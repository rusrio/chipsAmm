# ChipsAMM
## ChipsAMM is a gas-optimized Automated Market Maker (AMM) inspired by (but not standarly implemented) the ERC-6909 Minimal Multi-Token Interface.

The protocol functions as a wrapping layer for standard ERC-20 tokens. When users deposit assets, they receive an internal balance representation ("Chips"). This architecture allows the AMM to handle liquidity provision and swaps by simply updating internal accounting ledgers, avoiding the gas overhead associated with multiple external transferFrom calls required by traditional AMMs.

```mermaid
graph TD
    User((User))
    ERC20[(ERC-20 Contract)]
    AMM[Core.sol]
    Pool{Liquidity Pool}

    %% Deposit
    User -- 1. Approve & Deposit ERC20 --> AMM
    AMM -- 2. Mint Chip (ERC20 ID) --> User

    %% Swap
    User -- 4. Swap Chip A for Chip B --> Pool
    Pool -- 5. Update Internal Balances --> User
    subgraph "Gas Efficient execution"
    Pool
    end

    %% Withdraw
    User -- 6. Withdraw Chip B --> AMM
    AMM -- 7. Burn Chip (ID B) --> User
    AMM -- 8. Transfer Token B --> User
