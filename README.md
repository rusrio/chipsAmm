# ChipsAMM
## ChipsAMM is a gas-optimized Automated Market Maker (AMM) inspired by (but not standarly implemented) the ERC-6909 Minimal Multi-Token Interface.

The protocol functions as a wrapping layer for standard ERC-20 tokens. When users deposit assets, they receive an internal balance representation ("Chips"). This architecture allows the AMM to handle liquidity provision and swaps by simply updating internal accounting ledgers, avoiding the gas overhead associated with multiple external transferFrom calls required by traditional AMMs.

```mermaid
graph TD
    User((User))
    External_ERC20[(External ERC-20)]
    Core[Core.sol / AMM]

    subgraph Internal_State [Internal State]
        Mapping[Currency ID Mapping]
        UserBalance[User Chips Balance]
        PoolReserves[Pool Reserves]
    end

    %% 1. Deposit Flow
    User -- 1. deposit() --> Core
    Core -- transferFrom() --> External_ERC20
    Core -- Map Address to ID --> Mapping
    Core -- Credit Chips --> UserBalance

    %% 2. Pool Creation
    User -- 2. createPool() --> Core
    Core -- Initialize Pool --> PoolReserves
    UserBalance -- Transfer Liquidity --> PoolReserves

    %% 3. Swap Flow
    User -- 3. swapExactOutput() --> Core
    Core -- Check Reserves & Calc AmountIn --> PoolReserves
    
    subgraph Swap_Logic [Gas Efficient Swap]
        UserBalance -- Pay AmountIn (Chips) --> PoolReserves
        PoolReserves -- Receive AmountOut (Chips) --> UserBalance
    end

    %% 4. Withdraw Flow
    User -- 4. withdraw() --> Core
    UserBalance -- Debit Chips --> Core
    Core -- transfer() --> External_ERC20

    %% Styling
    style Core fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    style Internal_State fill:#fff9c4,stroke:#fbc02d,stroke-dasharray: 5 5
    style Swap_Logic fill:#e8f5e9,stroke:#2e7d32
