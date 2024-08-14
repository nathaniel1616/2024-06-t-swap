// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TSwapPool} from "src/TSwapPool.sol";
import {Test, console} from "forge-std/Test.sol";

// imports from Openzeppelin
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

// import token from "test/mock"
import {WETH} from "test/mock/WETH.sol";
import {PoolToken} from "test/mock/PoolToken.sol";

contract Handler2 is Test {
    TSwapPool public pool;

    PoolToken public poolToken;
    WETH public weth;

    //address
    address liquidityProvider2 = makeAddr("liquidityProvider2");
    address user = makeAddr("user");
    uint256 public constant STARTING_TOKEN_BALANCE = 100e18;
    uint256 public constant AMOUNT_TO_DEPOSIT = 10e18;
    uint256 public countLpDeposits;
    uint256 public countSWaps;

    //Ghost Variables
    int256 public actualDeltaX;
    int256 public expectedDeltaX;

    int256 public actualDeltaY;
    int256 public expectedDeltaY;

    int256 public startingX;
    int256 public startingY;

    constructor(TSwapPool _pool, address _weth) {
        pool = _pool;
        weth = WETH(_weth);
        poolToken = PoolToken(_pool.getPoolToken());
    }

    function depositLp(uint256 wethAmountToDeposit) external {
        wethAmountToDeposit = bound(
            wethAmountToDeposit,
            pool.getMinimumWethDepositAmount(),
            type(uint64).max
        );
        uint256 amountPoolTokensToDepositBasedOnWeth = pool
            .getPoolTokensToDepositBasedOnWeth(wethAmountToDeposit);
        _updateStartingDeltas(
            int256(wethAmountToDeposit),
            int256(amountPoolTokensToDepositBasedOnWeth)
        );
        vm.startPrank(liquidityProvider2);
        weth.mint(liquidityProvider2, wethAmountToDeposit);
        weth.approve(address(pool), wethAmountToDeposit);
        poolToken.mint(
            liquidityProvider2,
            amountPoolTokensToDepositBasedOnWeth
        );
        poolToken.approve(address(pool), amountPoolTokensToDepositBasedOnWeth);
        pool.deposit(
            wethAmountToDeposit,
            0,
            amountPoolTokensToDepositBasedOnWeth,
            uint64(block.timestamp)
        );
        vm.stopPrank();

        _updateEndingDeltas();
        countLpDeposits++;
    }

    function swapWethForPoolToken(uint256 wethAmountToSwap) external {
        if (
            weth.balanceOf(address(pool)) <= pool.getMinimumWethDepositAmount()
        ) {
            return;
        }
        wethAmountToSwap = bound(
            wethAmountToSwap,
            pool.getMinimumWethDepositAmount(),
            type(uint64).max
        );

        weth.mint(user, wethAmountToSwap);
        uint256 expectedPoolTokenAfterSwap = pool.getOutputAmountBasedOnInput(
            wethAmountToSwap,
            weth.balanceOf(address(pool)),
            poolToken.balanceOf(address(pool))
        );
        _updateStartingDeltas(
            int256(wethAmountToSwap),
            -1 * int256(expectedPoolTokenAfterSwap)
        );
        vm.startPrank(user);
        weth.approve(address(pool), wethAmountToSwap);
        uint256 actualPoolTokenBasedOnWethAfterSwap = pool.swapExactInput(
            IERC20(weth),
            wethAmountToSwap,
            IERC20(poolToken),
            expectedPoolTokenAfterSwap,
            uint64(block.timestamp)
        );

        console.log("expectedPoolTokenAfterSwap", expectedPoolTokenAfterSwap);
        console.log(
            "actualPoolTokenBasedOnWethAfterSwap",
            actualPoolTokenBasedOnWethAfterSwap
        );

        _updateEndingDeltas();
        countSWaps++;
    }

    // helper functions
    //updating startingDeltas
    function _updateStartingDeltas(
        int256 wethAmount,
        int256 poolTokenAmount
    ) internal {
        startingY = int256(poolToken.balanceOf(address(pool)));
        startingX = int256(weth.balanceOf(address(pool)));

        expectedDeltaX = wethAmount;
        expectedDeltaY = poolTokenAmount;
    }

    function _updateEndingDeltas() internal {
        uint256 endingPoolTokenBalance = poolToken.balanceOf(address(pool));
        uint256 endingWethBalance = weth.balanceOf(address(pool));

        int256 actualDeltaPoolToken = int256(endingPoolTokenBalance) -
            int256(startingY);
        int256 deltaWeth = int256(endingWethBalance) - int256(startingX);

        actualDeltaX = deltaWeth;
        actualDeltaY = actualDeltaPoolToken;
    }
}
