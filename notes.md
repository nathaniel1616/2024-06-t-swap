# Protocol Security Review Questions

## Basic Info

| Protocol Name                                |     |
| -------------------------------------------- | --- |
| Website                                      |     |
| Link To Documentation                        |     |
| Key Point of Contact (Name, Email, Telegram) |     |
| Link to Whitepaper, if any (optional)        |     |

## Code Details

| Link to Repo to be audited                              |                                          |
| ------------------------------------------------------- | ---------------------------------------- |
| Commit hash                                             | f426f57731208727addc20adb72cb7f5bf29dc03 |
| Number of Contracts in Scope                            | 2                                        |
| Total SLOC for contracts in scope                       | 195                                      |
| Complexity Score                                        | 174                                      |
| How many external protocols does the code interact with | 0                                        |
| Overall test coverage for code under audit              |                                          |

### In Scope Contracts                                                    

*You could run `tree ./src/ | sed 's/└/#/g; s/──/--/g; s/├/#/g; s/│ /|/g; s/│/|/g'` to get a nice output that works with pandoc for all files in `./src/`*

```
*Place in-scope contracts in here.*
src/PoolFactory.sol
src/TSwapPool.sol

```

- Solc Version: 0.8.20
- Chain(s) to deploy contract to: Ethereum
- Tokens:
  - Any ERC20 token

## About this projects (IN my own words)
This protocol allows users to swap ERC20 tokens in pools for a small fee. Pools are listed tokens where users can swap their token to get WETH and may use WETH to swap to another token. WETH token is kind of a mid point where users can swap to other tokens.
Pools where tokens are listed and contains amoint of erc20 tokens for swap for WETH . These tokens are provided by the liquidity provider deposit their tokens to provide luqidity for swapping a token . The liquidity provider get  percentage of the profits from the fees swap by the protocol.


## Actors / Roles
- Liquidity Providers: Users who have liquidity deposited into the pools. Their shares are represented by the LP ERC20 tokens. They gain a 0.3% fee every time a swap is made. 
- Users: Users who want to swap tokens.

## Known Issues

- None

###  poolTokensToDeposit in the `TSwapPool.sol:deposit`  calucation is fishy  per my caluclation 
 <!-- // weth / poolTokens = constant(k)  //@q this line and two lines above are different eqn ? poolTokens / constant(k) = weth -->

poolTokensToDeposit =  (wethToDeposit * PoolReserves) / wethReserves



## Tracking internal accounting 
@ q are there internal accounting like mapping to track  , tokens to mint, what has been minted , and who has amde a deposit

