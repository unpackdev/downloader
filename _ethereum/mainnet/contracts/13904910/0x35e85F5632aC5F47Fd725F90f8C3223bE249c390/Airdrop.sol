//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

/**
 * @dev Airdrop contract for aridrop Xana token to Zora holders
 */

contract Airdrop is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice Event emitted when sender address is modified
    event changeSenderAddr(address _newSenderAddr);

    /// @notice Event emitted when Xana address is modified
    event changeXanaAddr(address _newXanaAddr);

    /// @notice Event emitted when Zora address is modified
    event changeZoraAddr(address _newZoraAddr);

    /// @notice Xana token address
    IERC20 public XanaToken;

    /// @notice Zora token address
    IERC20 public ZoraToken;

    /// @notice Zora token holders
    address[] public TokenHolders;

    /// @notice Xana token Sender address
    address public XanaTokenSender;

    /// @notice holderaddress -> bool
    mapping(address => bool) public isHolder;

    /// @notice Contract Constructor
    /// @param _XanaToken Address of Xana token
    /// @param _ZoraToken Address of Zora token
    /// @param _XanaTokenSender Address of Xana token sender
    constructor(IERC20 _XanaToken, IERC20 _ZoraToken, address _XanaTokenSender) {
        XanaToken = _XanaToken;
        ZoraToken = _ZoraToken;
        XanaTokenSender = _XanaTokenSender;
    }

    /// @notice Method for adding holder address
    /// @dev Only admin
    /// @param _holders Address of Zora token holder
    function addAddr(address[] memory _holders) external onlyOwner {
        for(uint256 i = 0; i < _holders.length; i++) {
            if(!isHolder[_holders[i]]) {
                isHolder[_holders[i]] = true;
                TokenHolders.push(_holders[i]);
            }
        }
    }

    /// @notice Method for reset this contract
    /// @dev Only admin
    function reset() external onlyOwner {
        for(uint256 i = 0; i < TokenHolders.length; i++) {
                isHolder[TokenHolders[i]] = false;
        }
        TokenHolders = new address[](0);
    }

    /// @notice Method for getting number of holder
    function getNumberOfHolder() external view returns(uint256){
        return TokenHolders.length;
    }

    /// @notice Method for getting total amounts of holders
    function getTotalAmounts() external view returns(uint256){
        uint256 TotalAmounts;
        for(uint256 i = 0; i < TokenHolders.length; i++) {
            TotalAmounts += ZoraToken.balanceOf(TokenHolders[i]);
        }
        return TotalAmounts;
    }

    /// @notice Method for giving Xana token to Zora holders
    /// @dev Only admin
    /// @param _amountsOfXana Total amount of Xana token
    /// @param _amountsOfZora Total amount of Zora token
    function airdrop(uint256 _amountsOfXana, uint256 _amountsOfZora) external onlyOwner {
        require(TokenHolders.length > 0, "No holders");
        require(_amountsOfZora > 0, "Amounts of Zora must be larger than 0");
        require(_amountsOfXana > 0, "Amounts of Xana must be larger than 0");
        for(uint256 i = 0; i < TokenHolders.length; i++) {
            XanaToken.safeTransferFrom(XanaTokenSender, TokenHolders[i], _amountsOfXana.mul(ZoraToken.balanceOf(TokenHolders[i])).div(_amountsOfZora));
        }
    }

    /// @notice Method for setting sender address
    /// @dev Only admin
    /// @param _newSenderAddr New owner address
    function setSenderAddr(address _newSenderAddr)
        external
        onlyOwner
    {
        XanaTokenSender = _newSenderAddr;
        emit changeSenderAddr(_newSenderAddr);
    }

    /// @notice Method for setting Zora token address
    /// @dev Only admin
    /// @param _newZoraToken New Token address
    function setZoraTokenAddr(address _newZoraToken)
        external
        onlyOwner
    {
        ZoraToken = IERC20(_newZoraToken);
        emit changeZoraAddr(_newZoraToken);
    }

    /// @notice Method for setting Xana token address
    /// @dev Only admin
    /// @param _newXanaToken New Xana address
    function setXanaTokenAddr(address _newXanaToken)
        external
        onlyOwner
    {
        XanaToken = IERC20(_newXanaToken);
        emit changeXanaAddr(_newXanaToken);
    }
}
