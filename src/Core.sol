// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC6909} from "../lib/solmate/src/tokens/ERC6909.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";

contract Core {

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Core_PoolNotFound();
    error Core_CurrencyNotInPool();
    error Core_InsufficientLiquidity();
    error Core_InsufficientBalance();
    error Core_TransferFailed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    struct Pool {
        address currency0;
        address currency1;
        uint256 reserve0;
        uint256 reserve1;
    }

    uint256 public poolIdSequencer;
    uint256 public currencyIdSequencer;

    mapping(uint256 id => Pool) public idToPool;
    mapping(address user => mapping(uint256 currencyId => uint256 balance)) public userChipsBalance;
    mapping(address currency => uint256 id) public currencyToCurrencyId;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewPool(address indexed user, uint256 id);
    event SwapEvent(address indexed user, uint256 indexed poolId);
    event ChipsTransfer(address indexed from, address indexed to, uint256 currencyId, uint256 amount);
    event Deposit(address indexed user, address indexed currency, uint256 amount);
    event Withdraw(address indexed user, address indexed currency, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier poolChecker(uint256 poolId) {
        Pool memory pool = idToPool[poolId];
        if(pool.currency0 == address(0)){revert Core_PoolNotFound();}
        // if(currency =! pool.currency0 || currency =! pool.currency0) {Core_CurrencyNotInPool();}
        _;
    }

    modifier checkOrCreateCurrencyId(address currency) {
        uint256 currencyId = currencyToCurrencyId[currency];
        if (currencyId == 0) {
            currencyToCurrencyId[currency] = currencyIdSequencer++;
        }
        _;
    }

    constructor() {
        poolIdSequencer = 1;
        currencyIdSequencer = 1;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // deposit ERC20, get chips
    function deposit(address currency, uint256 amount) external checkOrCreateCurrencyId(currency) {
        bool success = ERC20(currency).transferFrom(msg.sender, address(this), amount);
        if(!success){revert Core_TransferFailed();}
        uint256 currencyId = currencyToCurrencyId[currency];
        userChipsBalance[msg.sender][currencyId] += amount;
        emit Deposit(msg.sender, currency, amount);
    }

    // lose chips, withdraw ERC20
    function withdraw(address currency, uint256 amount) external{
        uint256 currencyId = currencyToCurrencyId[currency];
        uint256 userBalance = userChipsBalance[msg.sender][currencyId];
        if(userBalance < amount) { revert Core_InsufficientBalance(); }

        userChipsBalance[msg.sender][currencyId] -= amount;
        userChipsBalance[address(this)][currencyId] -= amount;

        bool success = ERC20(currency).transfer(msg.sender, amount);
        if(!success){revert Core_TransferFailed();}

        emit Withdraw(msg.sender, currency, amount);
    }

    function swapExactOutput(
        uint256 poolId, 
        bool zeroForOne, 
        uint256 amountOut
    ) external poolChecker(poolId) returns (uint256 amountIn) {

        Pool storage pool = idToPool[poolId];

        // caching for gas efficiency
        uint256 r0 = pool.reserve0;
        uint256 r1 = pool.reserve1;
        uint256 currency0Id = currencyToCurrencyId[pool.currency0];
        uint256 currency1Id = currencyToCurrencyId[pool.currency1];
    
        (uint256 reserveIn, uint256 reserveOut) = zeroForOne
            ? (r0, r1)
            : (r1, r0);

        if(amountOut >= reserveOut){revert Core_InsufficientLiquidity();}

        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 998; // 0.2% fee

        // $$AmountIn = \frac{ReserveIn \cdot AmountOut \cdot 1000}{(ReserveOut - AmountOut) \cdot 997} + 1$$
        // +1 for safety, solidity trunks to 0
        amountIn = (numerator / denominator) + 1;

        if (zeroForOne) { // user sends currency0 -> gets currency1
            
            // update reserves
            pool.reserve0 += amountIn;
            pool.reserve1 -= amountOut;
            // user -> AMM
            _transferChips(msg.sender, address(this), currency0Id, amountIn);
        
            // AMM -> user
            _transferChips(address(this), msg.sender, currency1Id, amountOut);

        } else { // user sends currency1 -> gets currency0

            pool.reserve1 += amountIn;
            pool.reserve0 -= amountOut;
            
            _transferChips(msg.sender, address(this), currency1Id, amountIn);
            _transferChips(address(this), msg.sender, currency0Id, amountOut);
        }
    
    // verify xy = k
}
    function addLiquidity(uint256 poolId, uint256 currency0Amount, uint256 currency1Amount) public poolChecker(poolId) {
        Pool memory pool = idToPool[poolId];
        uint256 c0Id = currencyToCurrencyId[pool.currency0];
        uint256 c1Id = currencyToCurrencyId[pool.currency1];
        userChipsBalance[msg.sender][c0Id] -= currency0Amount;
        userChipsBalance[msg.sender][c1Id] -= currency1Amount;
        userChipsBalance[address(this)][c0Id] += currency0Amount;
        userChipsBalance[address(this)][c1Id] += currency1Amount;
    }

    function createPool(
        address _currency0,
        address _currency1,
        uint256 _reserve0,
        uint256 _reserve1
        ) 
        external checkOrCreateCurrencyId(_currency0) checkOrCreateCurrencyId(_currency1) {
        // currencyToCurrencyId[_currency0]
        Pool storage newPool = idToPool[poolIdSequencer];
        newPool.reserve0 = _reserve0;
        newPool.reserve1 = _reserve1;
        newPool.currency0 = _currency0;
        newPool.currency1 = _currency1;
        addLiquidity(poolIdSequencer, _reserve0, _reserve1);
        emit NewPool(msg.sender, poolIdSequencer);
        ++poolIdSequencer;
    }

    // function getPoolPricing(uint256 poolId) returns (uint256){
    //     Pool pool = idToPool(poolId);
    //     uint256 price = ;
    //     return price;
    // }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _transferChips(
        address sender,
        address receiver,
        uint256 id,
        uint256 amount
    ) internal returns (bool) {
        if (sender == address(this)){
            
        }
        uint256 senderBalance = userChipsBalance[sender][id];
        if (senderBalance < amount) { revert Core_InsufficientBalance(); }
        
        else {
            userChipsBalance[sender][id] -= amount;
            userChipsBalance[receiver][id] += amount;
            emit ChipsTransfer(sender, receiver, id, amount);
            return true;
        }
        
    }
}
