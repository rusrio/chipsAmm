// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {Currency} from "test/mocks/Currency.sol";
import {Core} from "../src/Core.sol";

contract CoreTest is Test {

    Core public coreAmm;
    address public alice;
    address public deployer;

    Currency public currency0;
    Currency public currency1;

    function setUp() public {

        alice = makeAddr("alice");
        deployer = makeAddr("deployer");

        coreAmm = new Core();
        
        // mocks
        vm.startPrank(deployer);
        currency0 = new Currency("Currency0", "CRN0", 18);
        currency1 = new Currency("Currency1", "CRN1", 18);

        currency0.mint(deployer, 10000e18);
        currency1.mint(deployer, 10000e18);

        ERC20(currency0).approve(address(coreAmm), 10000e18);
        ERC20(currency1).approve(address(coreAmm), 10000e18);

        coreAmm.deposit(address(currency0), 1000e18);
        coreAmm.deposit(address(currency1), 1000e18);

        coreAmm.createPool(address(currency0), address(currency1), 100e18, 100e18);
        vm.stopPrank();
    }

    function test_primero() external {
        console.log(coreAmm.poolIdSequencer());
        poolLogger(coreAmm.poolIdSequencer()-1);
    }

    function test_aliceCreatePoolThenAddLiquidity() external {

        vm.startPrank(deployer);
        currency0.mint(alice, 10000e18);
        currency1.mint(alice, 10000e18);
        vm.stopPrank();

        vm.startPrank(alice);

        ERC20(currency0).approve(address(coreAmm), 10000e18);
        ERC20(currency1).approve(address(coreAmm), 10000e18);

        coreAmm.deposit(address(currency0), 1000e18);
        coreAmm.deposit(address(currency1), 1000e18);

        coreAmm.createPool(address(currency0), address(currency1), 1e18, 1e18);
        coreAmm.addLiquidity(coreAmm.poolIdSequencer()-1, 5e18, 5e18);

        vm.stopPrank();
        poolLogger(coreAmm.poolIdSequencer()-1);
    }

    function test_aliceDeposit() external {
        vm.prank(deployer);
        currency0.mint(alice, 2e18);
        vm.startPrank(alice);
        ERC20(currency0).approve(address(coreAmm), 1e18);
        coreAmm.deposit(address(currency0), 1e18);
        vm.stopPrank();
        assert(coreAmm.userChipsBalance(alice, coreAmm.currencyToCurrencyId(address(currency0))) == currency0.balanceOf(address(coreAmm)));
        console.log("Alice chips balance: ", coreAmm.userChipsBalance(alice, coreAmm.currencyToCurrencyId(address(currency0))));
        console.log("Core AMM Currency0 balance: ", currency0.balanceOf(address(coreAmm)));
    }

    function test_aliceSwapExactOutput() external {
        poolLogger(1);
        vm.prank(deployer);
        currency0.mint(alice, 10e18);

        vm.startPrank(alice);
        ERC20(currency0).approve(address(coreAmm), 10e18);
        coreAmm.deposit(address(currency0), 10e18);
        coreAmm.swapExactOutput(1, true, 9e18);
        vm.stopPrank();
        poolLogger(1);
    }

    function poolLogger(uint256 poolId) internal {
        (address c0, address c1, uint256 r0, uint256 r1) = coreAmm.idToPool(poolId);
        console.log("Currency 0: ", c0);
        console.log("Currency 1: ", c1);
        console.log("Currency 0 reserves: ", r0);
        console.log("Currency 1 reserves: ", r1);
    }


}
