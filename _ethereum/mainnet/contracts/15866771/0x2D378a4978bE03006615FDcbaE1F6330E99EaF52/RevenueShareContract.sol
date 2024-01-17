// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC20.sol";


contract XLARevenueShareContract is Ownable {
    address public distributor;
    address payable [] public recipients;
    mapping(address => uint256) public recipientsPercentage;
    uint256 public numberOfRecipients = 0;

    event AddRecipient(address recipient, uint256 percentage, string name);
    event RemoveAll(address payable [] recipients);
    event DistributeToken(address token, uint256 amount);
    event DistributorChanged(address oldDistributor, address newDistributor);

    /**
     * @dev Throws if sender is not minter
     */
    modifier onlyDistributor {
        require(msg.sender == distributor, "Sender is not distributor");
        _;
    }

    constructor() {
        distributor = msg.sender;
    }

    fallback() external payable {
        _redistributeEth();
    }

    receive() external payable {
        _redistributeEth();
    }

    /**
     * @notice Internal function to redistribute ETH based on percentages assign to the recipients
     */
    function _redistributeEth() internal {
        uint256 recipientsLength = recipients.length;
        require(recipientsLength > 0, "empty recipients");

        for (uint256 i = 0; i < recipientsLength;) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];
            uint256 amountToReceive = msg.value / 10000 * percentage;
            (bool success,) = payable(recipient).call{value: amountToReceive}("");
            require(success, "Token transfer failed");
            unchecked{i++;}
        }
    }

    /**
     * @notice Internal function to check whether percentages are equal to 100%
     * @return valid boolean indicating whether sum of percentage == 100%
     */
    function _percentageIsValid() internal view returns (bool valid){
        uint256 recipientsLength = recipients.length;
        uint256 percentageSum;

        for (uint256 i = 0; i < recipientsLength;) {
            address recipient = recipients[i];
            percentageSum += recipientsPercentage[recipient];
            unchecked {i++;}
        }

        return percentageSum == 10000;
    }

    /**
     * @notice Internal function for adding recipient to revenue share
     * @param _recipient Fixed amount of token user want to buy
     * @param _percentage code of the affiliation partner
     */
    function _addRecipient(address payable _recipient, uint256 _percentage, string calldata _name) internal {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(recipientsPercentage[_recipient] == 0, "Recipient already added");
        recipients.push(_recipient);
        recipientsPercentage[_recipient] = _percentage;
        numberOfRecipients += 1;
        emit AddRecipient(_recipient, _percentage, _name);
    }

    /**
     * @notice function for removing all recipients
     */
    function removeAll() public onlyOwner {
        if (numberOfRecipients == 0) {
            return;
        }

        emit RemoveAll(recipients);
        for (uint256 i = 0; i < numberOfRecipients;) {
            address recipient = recipients[i];
            recipientsPercentage[recipient] = 0;
            unchecked{i++;}
        }
        delete recipients;
        numberOfRecipients = 0;
    }

    /**
     * @notice Set recipients in one TX
     * @param _newRecipients Addresses to be added
     * @param _percentages new percentages for
     */
    function setRecipients(
        address[] calldata _newRecipients,
        uint256[] calldata _percentages,
        string[] calldata _names
    ) external onlyOwner {
        uint256 newRecipientsLength = _newRecipients.length;
        require(newRecipientsLength == _percentages.length, "Recipients length does not much percentages");

        removeAll();

        for (uint256 i = 0; i < newRecipientsLength;) {
            _addRecipient(payable(_newRecipients[i]), _percentages[i], _names[i]);
            unchecked{i++;}
        }

        require(_percentageIsValid(), "Percentage Sum is not equal 100");
    }


    /**
     * @notice External function to redistribute ERC20 token based on percentages assign to the recipients
     */
    function redistributeToken(address token) external onlyDistributor {
        uint256 recipientsLength = recipients.length;
        require(recipientsLength > 0, "empty recipients");

        IERC20 erc20Token = IERC20(token);
        uint256 contractBalance = erc20Token.balanceOf(address(this));
        require(contractBalance > 0, "Nothing to distribute");

        for (uint256 i = 0; i < recipientsLength;) {
            address payable recipient = recipients[i];
            uint256 percentage = recipientsPercentage[recipient];
            uint256 amountToReceive = contractBalance / 10000 * percentage;
            erc20Token.transfer(recipient, amountToReceive);
            unchecked{i++;}
        }
        emit DistributeToken(token, contractBalance);
    }

    /**
     * @notice External function to set distributor address
     */
    function setDistributor(address newDistributor) external onlyOwner {
        require(newDistributor != distributor, "Distributor already configured");
        emit DistributorChanged(distributor, newDistributor);
        distributor = newDistributor;
    }
}
