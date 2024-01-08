// contracts/Bridge.sol
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Bridge is Ownable {
    using SafeMath for uint256;

    address public token = address(0x0);
    address public storageWallet;


    // ** EVENTS **
    event SwapEdge(address sender, uint256 amount, string destination);


    // ** MODIFIERS **

    /**
     * @dev Ensure that the storage address is valid. 
    */
    modifier validStorageAddress(address _storageWallet) {
        require(_storageWallet != address(0x0), "EDGEBridge: invalid storage wallet");
        require(_storageWallet != address(this), "EDGEBridge: invalid storage wallet");
        _;
    }

    /**
     * @dev Ensure that the token the Bridge will accept is a valid address. 
    */
    modifier validToken(address _token) {
        require(_token != address(0x0), "EDGEBridge: invalid token");
        require(_token != address(this), "EDGEBridge: invalid token");
        _;
    }

    /*****
     * @notice The constructor function to initialize the Bridge
     */
    constructor() public {}


    function receiveApproval(address _from, address _token, uint256 _amount, string memory _destination) public {
        // Simply perform validations on the passed arguments.
        swapEdge(_amount, _destination);
        
        // Perform the transfer from the sending address to the storage wallet.
        IERC20(_token).transferFrom(
            _from,
            address(storageWallet),
            _amount
        );

        emit SwapEdge(_from, _amount, _destination);
    }


    // ** END-USER BRIDGE METHODS **

    /**
     * @dev Start the process of exchanging EDGE ERC-20 for XE by depositing EDGE ERC-20 in the Bridge.
     * @param _amount - the amount of EDGE ERC-20 tokens (in WEI) to deposit in the Bridge in order to facilitate an exchange to XE.
     * @param _destination - the XE address the user wishes to credit with the exchanged tokens.
     * Reverted if the storageWallet has not been set.
     * NOTE transfer doesn't happen in this function in Phase 1, it happens in the receiveApproval method. Phase 2 may include a
     * 2 step process for approve + transfer.
     */
    function swapEdge(uint256 _amount, string memory _destination) public view validStorageAddress(storageWallet) validToken(token) {
        require(_amount > 0, "EDGEBridge: amount must be greater than zero");
        require(compareStrings(_destination, "") == false, "EDGEBridge: destination must be provided");

        // Perform the transfer from the message sender to the storage wallet defined in the contract.
        // IERC20(token).transferFrom(msg.sender, address(storageWallet), _amount);

        // emit SwapEdge(msg.sender, _amount, _destination);
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // ** CONTRACT MGMT METHODS **

    function setStorageWallet(address _addr) public onlyOwner {
        storageWallet = _addr;
    }

    /**
     * @dev Sets the address for the token that the Bridge will accept.
    */
    function setToken(address _token) public onlyOwner validToken(_token) {
        token = _token;
    }
}
