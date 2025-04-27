
## Crowdfunding 

## Overview
This smart contract allows users to contribute ETH to a crowfunding campaign with a set deadline. If the funds goal is met by the deadline, the owner can withdraw the funds. Otherwise, contributors can request refunds.

## Features
* Contribute ETH to a campaign

* Owner can withdraw funds if the goal is met after the deadline

* Contributors can refund their ETH before the deadline

* Tracks individual contributions

### Test
```shell
 forge test
```

### Deploy
```shell
forge script script/Crowdfunding.s.sol:DeployCrowdfunding
```


