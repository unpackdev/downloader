// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IERC20 {
    function upgrade(uint256 value) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract MystMigrator {
    using SafeMath for uint256;

    address internal _beneficiary; // address which will receive migrated tokens
    IERC20 public _legacyToken; // legacy MYST token
    IERC20 public _token; // new MYST token

    function getBeneficiary() public view returns (address) {
        return _beneficiary;
    }

    constructor(
        address legacyAddress,
        address newAddress,
        address beneficiary
    ) public {
        _legacyToken = IERC20(legacyAddress);
        _token = IERC20(newAddress);
        _beneficiary = beneficiary;
    }

    fallback() external payable {
        _legacyToken.upgrade(_legacyToken.balanceOf(address(this)));
        _token.transfer(_beneficiary, _token.balanceOf(address(this)));

        // Return any eth sent to this address
        if (msg.value > 0) {
            (bool success, ) = address(msg.sender).call{value: msg.value}("");
            require(
                success,
                "Unable to send ethers back, recipient may have reverted"
            );
        }
    }

    /**
     * Will call upgrade in legacy MYST token contract.
     * This will upgrade given amount of holded by this smart contract legacyMYST into new MYST
     */
    function upgrade(uint256 amount) public {
        _legacyToken.upgrade(amount);
    }

    /**
     * Setting new beneficiary of funds.
     */
    function setBeneficiary(address newBeneficiary) public {
        require(
            msg.sender == _beneficiary,
            "Only a current beneficiary can set new one"
        );
        require(
            newBeneficiary != address(0),
            "Beneficiary can't be zero addreess"
        );

        _beneficiary = newBeneficiary;
    }

    /**
       Transfers selected tokens into `_beneficiary` address.
    */
    function claimTokens(address token) public {
        require(
            _beneficiary != address(0),
            "Beneficiary can't be zero addreess"
        );
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(_beneficiary, amount);
    }
}