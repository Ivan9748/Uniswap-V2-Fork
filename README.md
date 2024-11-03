# Uniswap-V2-Fork
Uniswap V2 with different reward system for liquidity providers

First all collected fees are converted into project tokens, then they are stored on the smart contract and when amount of these tokens reaches certain threshold, they are distributed among liquidity providers in accordance with the volume of their liquidity.


How it works:
In Uniswap V2, when a user swaps one token to another, 0.3% of the amount of the first token are collected and sent to the pool. Thus, amount of tokens in the pool increases and liquidity tokens of liquidity providers represent more tokens. Also, the address set by factory contract owner owns 1/6 of the fees.

In this fork, when a user swaps one token for another, 0.3% of the amount of the first token are collected and sent to the reward contract and changed for project token. But this only happens under certain conditions, if the conditions are not met, the collected fee will be sent back to the pool (like Uniswap V2 does). Unlike Uniswap V2, there is no address set by the factory contract that will own 0.05%.

One of the conditions that must be met to change the fee for a project token:
- The token is a project token.
or
- The token has a pair with a project token, and the pair has enough liquidity
or
- The token has a pair with Wrapped ETH, and Wrapped ETH has a pair with a project token, and the pairs have enough liquidity
