![ref1]

# DAO Paykiken Geo Smart contracts security audit
[Smart contracts security audit.pdf](https://github.com/DAO-Paykiken-Geo/DAO-PAykiken-Geo-contracts/files/12330041/Smart.contracts.security.audit.pdf)
(Completed August, 2023)

[**paykiken.io** ](https://paykiken.io/)

## Identified and mitigated issues

***Issue 1. Contract Swap.sol***

[Identified issue](#_page4_x109.00_y62.00) 
–
[Solution](#_page5_x109.00_y30.00)

***Issue 2. Contract Governor.sol*** 

[Identified issue](#_page6_x109.00_y62.00)
–
[Solution](#_page7_x117.00_y46.00)

***Issue 3. Contract Swap.sol*** 

[Identified issue](#_page8_x109.00_y94.00) 
–
[Solution](#_page9_x124.00_y281.00)

***Issue 4. Contracts Governor.sol, Swap.sol*** 

[Identified issue](#_page10_x109.00_y62.00) 
–
[Solution](#_page11_x117.00_y30.00)

 ***Issue 5. Contract Swap.sol*** 

[Identified issue](#_page12_x109.00_y62.00) 
–
[Solution](#_page13_x109.00_y30.00)

 ***Issue 6. Contract Swap.sol, Team.sol, Hold.sol, Governor.sol***

[Identified issue](#_page14_x109.00_y77.00) 
–
[Solution](#_page14_x109.00_y254.00)

 ***Issue 7. Contract Swap.sol*** 

[Identified issue](#_page15_x109.00_y62.00) 
–
[Solution](#_page17_x109.00_y30.00)

[**Executive Summary**](#_page18_x62.00_y30.00)



<a name="_page2_x56.00_y30.00"></a>
## Introduction

DAO  Paykiken  Geo  is  the  first  decentralized  autonomous  organization  that implements the unique concept of collective investment in the commodity sectors of the global economy using blockchain technology and artificial intelligence. 

Paykiken Geo architecture is a system of smart contracts that form the main structure of the DAO Paykiken Geo in blockchain. This architecture realizes functions of token SWAP  (buy/sell),  token  price  growth  function,  voting,  founders  team  tokens freeze/unfreeze algorithm and token hold. This structure allows to join or leave the DAO at any given moment, stipulates token growth in geometrical progression in direct relation to the DAO USDT liquidity pool and utilizes a DAO voting mechanism for transactions made from DAO capital pool. 

DAO Paykiken Geo engaged the DAO community members and developers to perform a source code review of DAO Paykiken Geo Protocol. The objective of the audit was to evaluate the security of the smart contracts. The assessment covered the repository at [ https://github.com/DAO-Paykiken-Geo/contracts/tree/testnet-version ](https://github.com/DAO-Paykiken-Geo/contracts/tree/testnet-version) as  of  commit **d0b194c1b489e9b7e7bbd82a627840be28095859** tag audit, with focus on recent changes made to DAO Paykiken Geo smart contract architecture code. 

The Paykiken Geo Protocol was deployed to Nile Testnet in TRON blockchain with the following contracts being the main point of focus for the audit: 

- Governor.sol [(https://nile.tronscan.org/#/address/TWkhJreRfSCCNAC6RK9UFgfh6upg8SggiH)](https://nile.tronscan.org/#/address/TWkhJreRfSCCNAC6RK9UFgfh6upg8SggiH); 
- Hold.sol[ (https://nile.tronscan.org/#/address/TTTmXMG4yWADpXPFqb5WfBGgUDiLibNnMs);](https://nile.tronscan.org/#/address/TTTmXMG4yWADpXPFqb5WfBGgUDiLibNnMs) 
- Swap.sol[ (https://nile.tronscan.org/#/address/TFeJEt72MnghNQ21HMssq824u11V7i8yWB);](https://nile.tronscan.org/#/address/TFeJEt72MnghNQ21HMssq824u11V7i8yWB) 
- Team.sol [(https://nile.tronscan.org/#/address/TXQVUVDemwBCgozLhK57uSBPaJLeHq2Stt)](https://nile.tronscan.org/#/address/TXQVUVDemwBCgozLhK57uSBPaJLeHq2Stt). 

The information presented in this document is provided as is and without warranty. Vulnerability assessments are a “point in time” analysis and as such it is possible that something in the environment could have changed since the tests reflected in this report were  run.  This  report  should  not  be  considered  a  perfect  representation  of  the  risks threatening the analyzed system, networks and applications. 



## Identified and mitigated issues 

### Issue 1. Contract Swap.sol

1. **Identified<a name="_page4_x109.00_y62.00"></a> issue:**  

“Can’t sell PAYKIK tokens that were not originally bought from the Swap smart contract”. 

- **Severity** - critical;* 
- **Type** – unrecorded tokens; 
- **Vulnerable SHA1** - 927ef030bc47106473b406508fb4fb7ac6651915; 
- **Mitigated SHA1** - ccf07974d6d1965fd62df7c1c8bef1fc441c6dd. 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.003.jpeg)

*Picture 1. Vulnerable sell() method (927ef030bc47106473b406508fb4fb7ac6651915)* 

**Vulnerability description:**  

Tokens that are frozen on the Team.sol contract cannot be sold on the **Swap.sol** contract because the balance of 32 holders of frozen PAYKIK tokens on the **Team.sol** contract has been identified as having a value of zero (**totalBuy[msg.sender]**). This is because these PAYKIK tokens were not originally purchased from the **Swap.sol** contract. 

2. **Solution:<a name="_page5_x109.00_y30.00"></a>** 

The new logic stipulates that the users can sell more PAYKIK tokens than they have bought  (**totalBuy[msg.sender]**).  This  situation  is  only  possible  if  the  tokens  were purchased outside of the Swap.sol smart contract, for example, on a P2P platform. The creators of the PAYKIK protocol considered this scenario to be possible. 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.004.jpeg)

*Picture 2. Patch version of sell() method (ccf07974d6d1965fd62df7c1c8bef1fc441c6dd)* 

### Issue 2. Contract Governor.sol.

1. **Identified<a name="_page6_x109.00_y62.00"></a> issue:**  

“cancelVotes() Integer — Underflow”. 

- **Severity** - critical;
- **Type** - integer-underflow; 
- **Vulnerable SHA1** - 6361528e7f39f2894bcb4be42f9690d1d977ca09; 
- **Mitigated SHA1** - 026845dffee0493a0fbe2b03fda0893629fbf3c9. 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.005.png)

*Picture 3. Vulnerable cancelVotes() method (6361528e7f39f2894bcb4be42f9690d1d977ca09)* 

**Vulnerability description:**  

During iteration, cycle (**for (uint256 i = userPolls[msg.sender].length - 1; i >= 0; i- -)**) will get Integer-Underflow as, the last iteration will be equal to 0 and operation 0 - 1 will happen as the result of decrementation. 

2. **Solution:<a name="_page7_x117.00_y46.00"></a>** 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.006.jpeg)

*Picture 4. Patch version of cancelVotes() method (026845dffee0493a0fbe2b03fda0893629fbf3c9)* 

**Issue 3. Contract Swap.sol.** 

1. **Identified<a name="_page8_x109.00_y94.00"></a> issue:**  

“getBuyRate() calculates price for cases that are not stipulated by the algorithm”. 

- **Severity** - critical;
- **Type** - manipulation over the price of a token; 
- **Vulnerable SHA1** - dfca22e62aa17665dd00de1c49f087d2c77a6be7; 
- **Mitigated SHA1** - 0ccf6f3c18e54441e2a80d2a4288e8558d93c1fd. 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.007.jpeg)

*Picture 5. Vulnerable sell() method (dfca22e62aa17665dd00de1c49f087d2c77a6be7)* 

**Vulnerability description:**  

Before purchase **Swap** contract call’s function (**getBuyRate()**). To ensure accurate calculation, the USDT balance in the **Governor** smart contract must exceed 1 USDT. Failure to meet this requirement may result in incorrect values and financial exploitation. Notably, the algorithm is initially calculated based on pools with a ratio of 1:1 or 1:1+ (the latter indicating the USDT pool).  

In this case, we should not allow the user to buy PAYKIK if the USDT pool state is (**<1\*10\*\*usdtContract.decimals()**). 

*Picture 6.* 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.008.jpeg)

*Picture 6. getBuyRate() method without validation USDT pool exhaustion (0ccf6f3c18e54441e2a80d2a4288e8558d93c1fd)* 

2. ***Solution:***

<a name="_page9_x124.00_y281.00"></a>Validation was added (**require(usdtPool >=1\*1e6,”Governor pool should be more than 1 USDT”**). In this case smart contract won’t conduct calculations if USDT pool is less than 1.** 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.009.jpeg)

*Picture 7. Patch version of getBuyRate() method (0ccf6f3c18e54441e2a80d2a4288e8558d93c1fd)* 

### Issue 4. Contract Governor.sol, Swap.sol.

*4.1.* <a name="_page10_x109.00_y62.00"></a>**Identified issue:**  

“getBuyRate() calculates price for cases that are not stipulated by the algorithm”. 

- **Severity** - critical;
- **Type** - Integer-Underflow; 
- **Vulnerable** **SHA1** - 0c981511066be1a3c8888e5d7e5b9bb6922d0795; 
- **Mitigated** **SHA1** - d0b194c1b489e9b7e7bbd82a627840be28095859. 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.010.jpeg)

*Picture 8. Vulnerable \_getParticipationRate() method (0c981511066be1a3c8888e5d7e5b9bb6922d0795)* 

**Vulnerability description:**  

In this code block, circulation is not calculated relative to emission. This is an error as when PAYKIKs are unlocked from the **Team** contract pool, they migrate to **Swap's** balance. 

Taking into account that (**paykikEmissionOnSwap**) is equal to (**18\*1e5\*1e8**) the current balance (**currentSwapBalance**) can tend to a number equal to the emission amount - in particular (**2\*1e6\*1e8**). 

Therefore, this can lead to **((paykikEmissionOnSwap – currentSwapBalance) <0)**, that will result in Integer- Underflow, as it works with (unsigned integers). 


2. **Solution:<a name="_page11_x117.00_y30.00"></a>** 

The line **(uint256 circulatingAmount = teamTotalSent + (paykikEmission + (paykikEmissionOnSwap – currentSwapBalance)**; was replaced with **uint256 circulatingAmount = getCirculationPaykik())**. In this case the circulation is calculated according to the emission, which is correct. 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.011.jpeg)

*Picture 9. Patch version of calculation of paykiks circulation (d0b194c1b489e9b7e7bbd82a627840be28095859)* 


### Issue 5. Contract Swap.sol 

*5.1.* <a name="_page12_x109.00_y62.00"></a>**Identified issue:**  

“sell() leads to Denial Of Service by selling PAYKIK, without leaving USDT in the 

pool”. 

- **Severity** - high;
- **Type** - Dos; 
- **Vulnerable SHA1** - 5cfb1e6cefeb9a8e5f4beb807b0b10160743a995; 
- **Mitigated SHA1** - d0b194c1b489e9b7e7bbd82a627840be28095859. 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.012.jpeg)

*Picture 10. Vulnerable sell()method (5cfb1e6cefeb9a8e5f4beb807b0b10160743a995)* 

**Vulnerability description:**  

Price calculation method **getBuyRate()** stipulates a condition **require(usdtPool >= 1\*1e6, "Governor pool should be more than 1 USDT")**. In case when this condition is not fulfilled, the user won’t be able make a purchase. 

In **sell()** method the user is not limited in terms of sell amount of the **PAYKIK → USDT** pair, that can lead to a condition when USDT on the balance is equal to **< 1 \* 1e6**. 

This case can lead to DoS, because until USDT balance on Governor contract is less than **1 \* 1e6**, users won’t be able to buy PAYKIK tokens.* 

**require(totalPay.div(10\*\*(paykikDecimals - usdtDecimals)) + 10\*\*usdtDecimals <= usdtToken.balanceOf(governorAddress), "Cant sell, USDT Governor pool too small");** this function won’t allow USDT pool to be less than < 1 \* 1e6 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.013.jpeg)

*Picture 11. Patch version of sell() method (d0b194c1b489e9b7e7bbd82a627840be28095859)*



Picture 11. Patch block code

**Issue 6. Contract Swap.sol, Team.sol, Hold.sol, Governor.sol** 

1. **Identified<a name="_page14_x109.00_y77.00"></a> issue:**  

“Transfer of all local mathematical operations to SafeMath.sol function”.

- **Severity** - low;
- **Type** - mathematical vulnerabilities; 
- **Vulnerable SHA1**-; 
- **Mitigated SHA1** -. 

**Vulnerability description:** 

To maintain security standards, all of the mathematical calculations should be conducted using SafeMath.sol function. 

2. **Solution:<a name="_page14_x109.00_y254.00"></a>** 

SafeMath.sol function was successfully integrated. 

Reference:[ https://github.com/DAO-Paykiken-Geo/contracts/blob/testnet- version/contracts/base/SafeMath.sol ](https://github.com/DAO-Paykiken-Geo/contracts/blob/testnet-version/contracts/base/SafeMath.sol)


### Issue 7. Contract Governor.sol.

1. **Identified<a name="_page15_x109.00_y62.00"></a> issue:**  

“Wrong msg.sender context in submitVote()”. 

- **Severity** - critical;
- **Type** - erroneous context; 
- **Vulnerable SHA1** - 0c2f8eadfe44384a0b93087ed2c0f69dafa287f3; 
- **Mitigated SHA1** - f3c7e29a242d2cdf2098126f193911cb147d905d. 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.014.png)

*Picture 12. Vulnerable submitVote() method (0c2f8eadfe44384a0b93087ed2c0f69dafa287f3)* 

**Vulnerability description:** 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.015.jpeg)

*Picture 13. Erroneuos context of deposit() method (0c2f8eadfe44384a0b93087ed2c0f69dafa287f3)* 

When  deposit  method  of  the  **holdContract**  is  called,  **Governor**  contract  is  the transaction initiator, therefore the contract address will operate as **msg.sender** of built-in variable. 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.016.jpeg)

*Picture 14. Implementation of deposit() method*  

As the result **Hold** smart contract will try to keep Paykik TRC20 from the **Governor** contract address, instead from the user that initially called the **submitVote()** method. 

2. **Solution:<a name="_page17_x109.00_y30.00"></a>** 

A function could be utilized, which is similar to the methods realized in ERC20 standard **transfer()/transferFrom()**. 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.017.jpeg)

*Picture 15. New implementation of the deposit logic with the right context* 

And transfer when calling **sumbitVote()** to the **transferFrom()** method as an argument from the value of the variable **msg.sender** - which will be the user's address. 

![](https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.018.png)

*Picture 16. Patch version of deposit logic       (f3c7e29a242d2cdf2098126f193911cb147d905d)* 

<a name="_page18_x62.00_y30.00"></a>               **Executive Summary**

The  DAO  community  tests  identified  7  potential  improvement  points  that  were mitigated and are the main assessment subject under this audit. The modifications included:  

- Swap.sol - “Unrecorded tokens”; 
- Governor.sol - “Integer-Underflow; 
- Swap.sol - “Manipulation over the price of tokens”; 
- Governor.sol, Swap.sol - “Integer-Underflow”; 
- Swap.sol - “DoS”; 
- Swap.sol, Team.sol, Hold.sol, Governor.sol - “Mathematical vulnerabilities”; 
- Governor.sol - “Erroneous context”. 

The contracts are specified to be complied with Solidity 0.8.21 this is the latest maintenance release of the 0.8.x series.  

The contracts compile without any errors or warnings. Linting does not show any problems. The code is very clean and well commented. 

The repository contains a very comprehensive set of  **66** unit tests for the smart contracts. After taking care of some minor hiccups (‘out of memory’ errors and timeouts), all tests passed. 

Results: 

All of the changes made to smart contracts were successful. The Paykiken Geo Protocol is stable and secure. 

[ref1]: https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.001.png
[ref2]: https://paykiken.io/audit/f7c29f3d-4fc6-49ad-972e-761376e4777c.002.png
