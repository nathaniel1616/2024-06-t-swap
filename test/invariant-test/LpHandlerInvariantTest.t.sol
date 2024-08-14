// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { LpHandler } from "./LpHandler.t.sol";

contract LpHandlerInvariantTest is StdInvariant, Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;
    LpHandler lpHandler;
    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");
    uint256 public constant LP_STARTING_BALANCE = 200e18;
    uint256 public constant LP_INITIAL_DEPOSIT = 100e18;
    uint256 public constant USER_STARTING_BALANCE = 10e18;
    uint256 public MINIMUM_WETH_DEPOSIT;
    uint256 public constant PRECISION = 1e18;

    function setUp() external {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        pool = new TSwapPool(address(poolToken), address(weth), "LTokenA", "LA");
        MINIMUM_WETH_DEPOSIT = pool.getMinimumWethDepositAmount();
        lpHandler = new LpHandler(pool, poolToken, weth);

        weth.mint(liquidityProvider, LP_STARTING_BALANCE);
        poolToken.mint(liquidityProvider, LP_STARTING_BALANCE);

        weth.mint(user, USER_STARTING_BALANCE);
        poolToken.mint(user, USER_STARTING_BALANCE);

        /// TODO: add invariant target contract
        targetContract(address(lpHandler));
        // targetSender(address(user));
        targetSender(address(liquidityProvider));
    }

    function invariant_LPCanDepositHander() public {
        uint256 wethBalanceOfLiquidProvider = weth.balanceOf(liquidityProvider);
        uint256 poolTokenBalanceOfLiquidProvider = poolToken.balanceOf(liquidityProvider);
        console.log("wethBalanceOfLiquidProvider", wethBalanceOfLiquidProvider);
        console.log("number of deposits", lpHandler.countLpDeposit());
        assertEq(weth.balanceOf(address(pool)), LP_STARTING_BALANCE - wethBalanceOfLiquidProvider);
    }

    //     function testDepositSwap() public {
    //     vm.startPrank(liquidityProvider);
    //     weth.approve(address(pool), 100e18);
    //     poolToken.approve(address(pool), 100e18);
    //     pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
    //     vm.stopPrank();

    //     vm.startPrank(user);
    //     poolToken.approve(address(pool), 10e18);
    //     // After we swap, there will be ~110 tokenA, and ~91 WETH
    //     // 100 * 100 = 10,000
    //     // 110 * ~91 = 10,000
    //     uint256 expected = 9e18;

    //     pool.swapExactInput(poolToken, 10e18, weth, expected, uint64(block.timestamp));
    //     assert(weth.balanceOf(user) >= expected);
    // }
    function invariant__UserCanMkaeSwap() public {
        uint256 wethBalanceOfUser = weth.balanceOf(user);
        uint256 poolTokenBalanceOfLiquidProvider = poolToken.balanceOf(liquidityProvider);
        console.log("weth balance of user", wethBalanceOfUser);
        // console.log("number of deposits", depositHandler.countUserDeposit());
        assertEq(wethBalanceOfUser, 1);
    }
}
