#!/bin/bash
set -e

# 🎨 Enhanced Gensyn Auto Setup Banner with User-Provided ASCII
BANNER=$(cat << 'EOF'
██████╗ ███████╗██╗   ██╗██╗██╗     
██╔══██╗██╔════╝██║   ██║██║██║     
██║  ██║█████╗  ██║   ██║██║██║     
██║  ██║██╔══╝  ╚██╗ ██╔╝██║██║     
██████╔╝███████╗ ╚████╔╝ ██║███████╗
╚═════╝ ╚══════╝  ╚═══╝  ╚═╝╚══════╝
EOF
)

# 🔢 Random color selection
COLORS=(31 32 33 34 35 36 91 92 93 94 95 96)
COLOR=${COLORS[$RANDOM % ${#COLORS[@]}]}

# 🎉 Show banner
echo -e "\n\e[1;${COLOR}m$BANNER\e[0m"
echo -e "🔧 Starting Gensyn Auto Error Solve — Say thanks to DEVIL!\n"

# 🏜️ Step 5: Write rg-swarm.yaml config file only if rl-swarm exists
if [ -d "./rl-swarm" ]; then
  RL_DIR="./rl-swarm"
elif [ -d "$HOME/rl-swarm" ]; then
  RL_DIR="$HOME/rl-swarm"
else
  echo -e "\n❌ Error: 'rl-swarm' folder not found. Please clone it first."
  exit 1
fi

CONFIG_PATH="$RL_DIR/rgym_exp/config/rg-swarm.yaml"
echo -e "\n🔧 Writing final rg-swarm.yaml config to $CONFIG_PATH..."

mkdir -p "$(dirname "$CONFIG_PATH")"
cat > "$CONFIG_PATH" << 'EOF'
log_dir: ${oc.env:ROOT,.}/logs

training:
  max_round: 1000000
  max_stage: 1
  hf_push_frequency: 1
  num_generations: 2
  num_transplant_trees: 1
  seed: 42
  fp16: false
  bf16: false

blockchain:
  alchemy_url: "https://gensyn-testnet.g.alchemy.com/public"
  contract_address: ${oc.env:SWARM_CONTRACT,null}
  org_id: ${oc.env:ORG_ID,null}
  mainnet_chain_id: 685685
  modal_proxy_url: "http://localhost:3000/api/"

communications:
  initial_peers:
    - '/ip4/38.101.215.12/tcp/30011/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ'
    - '/ip4/38.101.215.13/tcp/30012/p2p/QmWhiaLrx3HRZfgXc2i7KW5nMUNK7P9tRc71yFJdGEZKkC'
    - '/ip4/38.101.215.14/tcp/30013/p2p/QmQa1SCfYTxx7RvU7qJJRo79Zm1RAwPpkeLueDVJuBBmFp'

eval:
  judge_base_url: https://swarm-judge-102957787771.us-east1.run.app

hydra:
  run:
    dir: ${log_dir}

game_manager:
  _target_: rgym_exp.src.manager.SwarmGameManager
  max_stage: ${training.max_stage}
  max_round: ${training.max_round}
  log_dir: ${log_dir}
  hf_token: ${oc.env:HUGGINGFACE_ACCESS_TOKEN,null}
  hf_push_frequency: ${training.hf_push_frequency}
  run_mode: "train_and_evaluate"
  bootnodes: ${communications.initial_peers}
  game_state:
    _target_: genrl.state.game_state.GameState
    round: 0
    stage: 0
  reward_manager:
    _target_: genrl.rewards.DefaultRewardManager
    reward_fn_store:
      _target_: genrl.rewards.reward_store.RewardFnStore
      max_rounds: ${training.max_round}
      reward_fn_stores:
        - _target_: genrl.rewards.reward_store.RoundRewardFnStore
          num_stages: ${training.max_stage}
          reward_fns:
            - _target_: rgym_exp.src.rewards.RGRewards
  trainer:
    _target_: rgym_exp.src.trainer.GRPOTrainerModule
    models:
      - _target_: transformers.AutoModelForCausalLM.from_pretrained
        pretrained_model_name_or_path: ${oc.env:MODEL_NAME, Gensyn/Qwen2.5-0.5B-Instruct}
    config:
      _target_: trl.trainer.GRPOConfig
      logging_dir: ${log_dir}
      fp16: ${training.fp16}
      bf16: ${training.bf16}
    log_with: wandb
    log_dir: ${log_dir}
    epsilon: 0.2
    epsilon_high: 0.28
    num_generations: ${training.num_generations}
    judge_base_url: ${eval.judge_base_url}
  data_manager:
    _target_: rgym_exp.src.data.ReasoningGymDataManager
    yaml_config_path: "rgym_exp/src/datasets.yaml"
    num_train_samples: 1
    num_evaluation_samples: 0
    num_generations: ${training.num_generations}
    system_prompt_id: 'default'
    seed: ${training.seed}
    num_transplant_trees: ${training.num_transplant_trees}
  communication:
    _target_: genrl.communication.hivemind.hivemind_backend.HivemindBackend
    initial_peers: ${communications.initial_peers}
    identity_path: ${oc.env:IDENTITY_PATH,null}
    startup_timeout: 120
    beam_size: 50
  coordinator:
    _target_: genrl.blockchain.coordinator.ModalSwarmCoordinator
    web3_url: ${blockchain.alchemy_url}
    contract_address: ${blockchain.contract_address}
    org_id: ${blockchain.org_id}
    modal_proxy_url: ${blockchain.modal_proxy_url}

default_large_model_pool:
  - nvidia/AceInstruct-1.5B
  - dnotitia/Smoothie-Qwen3-1.7B
  - Gensyn/Qwen2.5-1.5B-Instruct

default_small_model_pool:
  - Gensyn/Qwen2.5-0.5B-Instruct
  - Qwen/Qwen3-0.6B
EOF

echo "✅ Final config written to: $CONFIG_PATH"

# 🔐 Step 6: Set permissions for .pem key (optional, safe fallback)
SWARM_KEY="$HOME/.swarm/keys/swarm.pem"
if [ -f "$SWARM_KEY" ]; then
  chmod 600 "$SWARM_KEY"
  echo "🔐 Permissions set for swarm.pem"
fi

# 🎉 Done
echo -e "\n🎉 Setup complete! Your system is now fully ready 🔍"
echo -e "📂 You can now run the swarm & start node like a boss.\n"
