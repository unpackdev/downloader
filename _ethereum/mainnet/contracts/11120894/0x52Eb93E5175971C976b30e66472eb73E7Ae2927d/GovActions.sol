pragma solidity ^0.6.7;

abstract contract Setter {
    function modifyParameters(bytes32, address) virtual public;
    function modifyParameters(bytes32, uint) virtual public;
    function modifyParameters(bytes32, int) virtual public;
    function modifyParameters(bytes32, uint, uint) virtual public;
    function modifyParameters(bytes32, uint, uint, address) virtual public;
    function modifyParameters(bytes32, bytes32, uint) virtual public;
    function modifyParameters(bytes32, bytes32, address) virtual public;
    function setDummyPIDValidator(address) virtual public;
    function addAuthorization(address) virtual public;
    function removeAuthorization(address) virtual public;
    function initializeCollateralType(bytes32) virtual public;
    function updateAccumulatedRate() virtual public;
    function redemptionPrice() virtual public;
    function setTotalAllowance(address,uint256) virtual external;
    function setPerBlockAllowance(address,uint256) virtual external;
    function taxMany(uint start, uint end) virtual public;
    function taxSingle(bytes32) virtual public;
    function setAllowance(address, uint256) virtual external;
    function addReader(address) virtual external;
    function removeReader(address) virtual external;
    function addAuthority(address account) virtual external;
    function removeAuthority(address account) virtual external;
    function changePriceSource(address priceSource_) virtual external;
    function stopFsm(bytes32 collateralType) virtual external;
    function start() virtual external;
    function changeNextPriceDeviation(uint deviation) virtual external;
    function setName(string calldata name) virtual external;
    function setSymbol(string calldata symbol) virtual external;
}

abstract contract GlobalSettlementLike {
    function shutdownSystem() virtual public;
    function freezeCollateralType(bytes32) virtual public;
}

abstract contract PauseLike {
    function setAuthority(address) virtual public;
    function setDelay(uint) virtual public;
    function setDelayMultiplier(uint) virtual public;
    function setProtester(address) virtual public;
}

contract GovActions {
    uint constant internal RAY = 10 ** 27;

    function modifyParameters(address targetContract, bytes32 parameter, address data) public {
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function modifyParameters(address targetContract, bytes32 parameter, uint data) public {
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function modifyParameters(address targetContract, bytes32 parameter, int data) public {
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function modifyParameters(address targetContract, bytes32 collateralType, bytes32 parameter, uint data) public {
        Setter(targetContract).modifyParameters(collateralType, parameter, data);
    }

    function modifyParameters(address targetContract, bytes32 collateralType, bytes32 parameter, address data) public {
        Setter(targetContract).modifyParameters(collateralType, parameter, data);
    }

    function modifyParameters(address targetContract, bytes32 parameter, uint data1, uint data2) public {
        Setter(targetContract).modifyParameters(parameter, data1, data2);
    }

    function modifyParameters(address targetContract, bytes32 collateralType, uint data1, uint data2, address data3) public {
        Setter(targetContract).modifyParameters(collateralType, data1, data2, data3);
    }

    function modifyTwoParameters(
      address targetContract1,
      address targetContract2,
      bytes32 parameter1,
      bytes32 parameter2,
      uint data1,
      uint data2
    ) public {
      Setter(targetContract1).modifyParameters(parameter1, data1);
      Setter(targetContract2).modifyParameters(parameter2, data2);
    }

    function modifyTwoParameters(
      address targetContract1,
      address targetContract2,
      bytes32 collateralType1,
      bytes32 collateralType2,
      bytes32 parameter1,
      bytes32 parameter2,
      uint data1,
      uint data2
    ) public {
      Setter(targetContract1).modifyParameters(collateralType1, parameter1, data1);
      Setter(targetContract2).modifyParameters(collateralType2, parameter2, data2);
    }

    function removeAuthorizationAndModify(
      address targetContract,
      address to,
      bytes32 parameter,
      uint data
    ) public {
      Setter(targetContract).removeAuthorization(to);
      Setter(targetContract).modifyParameters(parameter, data);
    }

    function updateRateAndModifyParameters(address targetContract, bytes32 parameter, uint data) public {
        Setter(targetContract).updateAccumulatedRate();
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function taxManyAndModifyParameters(address targetContract, uint start, uint end, bytes32 parameter, uint data) public {
        Setter(targetContract).taxMany(start, end);
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function taxSingleAndModifyParameters(address targetContract, bytes32 collateralType, bytes32 parameter, uint data) public {
        Setter(targetContract).taxSingle(collateralType);
        Setter(targetContract).modifyParameters(collateralType, parameter, data);
    }

    function updateRedemptionRate(address targetContract, bytes32 parameter, uint data) public {
        Setter(targetContract).redemptionPrice();
        Setter(targetContract).modifyParameters(parameter, data);
    }

    function setDummyPIDValidator(address rateSetter, address oracleRelayer, address dummyValidator) public {
        Setter(rateSetter).modifyParameters("pidValidator", dummyValidator);
        Setter(oracleRelayer).redemptionPrice();
        Setter(oracleRelayer).modifyParameters("redemptionRate", RAY);
    }

    function addReader(address validator, address reader) public {
        Setter(validator).addReader(reader);
    }

    function removeReader(address validator, address reader) public {
        Setter(validator).removeReader(reader);
    }

    function addAuthority(address validator, address account) public {
        Setter(validator).addAuthority(account);
    }

    function removeAuthority(address validator, address account) public {
        Setter(validator).removeAuthority(account);
    }

    function setTotalAllowance(address targetContract, address account, uint256 rad) public {
        Setter(targetContract).setTotalAllowance(account, rad);
    }

    function setPerBlockAllowance(address targetContract, address account, uint256 rad) public {
        Setter(targetContract).setPerBlockAllowance(account, rad);
    }

    function addAuthorization(address targetContract, address to) public {
        Setter(targetContract).addAuthorization(to);
    }

    function removeAuthorization(address targetContract, address to) public {
        Setter(targetContract).removeAuthorization(to);
    }

    function initializeCollateralType(address targetContract, bytes32 collateralType) public {
        Setter(targetContract).initializeCollateralType(collateralType);
    }

    function changePriceSource(address fsm, address priceSource) public {
        Setter(fsm).changePriceSource(priceSource);
    }

    function stopFsm(address fsmGovInterface, bytes32 collateralType) public {
        Setter(fsmGovInterface).stopFsm(collateralType);
    }

    function start(address fsm) public {
        Setter(fsm).start();
    }

    function setName(address coin, string memory name) public {
        Setter(coin).setName(name);
    }

    function setSymbol(address coin, string memory symbol) public {
        Setter(coin).setSymbol(symbol);
    }

    function changeNextPriceDeviation(address fsm, uint deviation) public {
        Setter(fsm).changeNextPriceDeviation(deviation);
    }

    function shutdownSystem(address globalSettlement) public {
        GlobalSettlementLike(globalSettlement).shutdownSystem();
    }

    function setAuthority(address pause, address newAuthority) public {
        PauseLike(pause).setAuthority(newAuthority);
    }

    function setProtester(address pause, address protester) public {
        PauseLike(pause).setProtester(protester);
    }

    function setDelay(address pause, uint newDelay) public {
        PauseLike(pause).setDelay(newDelay);
    }

    function setAuthorityAndDelay(address pause, address newAuthority, uint newDelay) public {
        PauseLike(pause).setAuthority(newAuthority);
        PauseLike(pause).setDelay(newDelay);
    }

    function setDelayMultiplier(address pause, uint delayMultiplier) public {
        PauseLike(pause).setDelayMultiplier(delayMultiplier);
    }

    function setAllowance(address join, address account, uint allowance) public {
        Setter(join).setAllowance(account, allowance);
    }

    function multiSetAllowance(address join, address[] memory accounts, uint[] memory allowances) public {
        for (uint i = 0; i < accounts.length; i++) {
            Setter(join).setAllowance(accounts[i], allowances[i]);
        }
    }
}