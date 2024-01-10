//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;
import "./ECDSA.sol";
import "./Ownable.sol";
interface IERC20 {
    function burn(address to, uint256 value) external returns (bool);
    function mint(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
}

contract Bridge is Ownable{
    
    using ECDSA for bytes32;

    // set in constructor
    uint public immutable chainId;
    // signer => tokenAddress => isValid
    mapping(address => mapping(address => bool)) public trustedSigner;
    mapping(uint => bool) public orders;

    event PayInEvent(
        address indexed user,
        address indexed tokenAddress,
        uint256 indexed orderId
    );

    event PayOutEvent(
        address indexed user,
        address indexed tokenAddress,
        uint256 indexed orderId
    );

    event SignerUpdated(
        address signer,
        address tokenAddress,
        bool isValid
    );

    /// @param _chainId id of chain
    constructor(uint _chainId) {
        chainId = _chainId;
    }

    /// @dev transfer tokens from user
    /// @param _orderId unique order id
    /// @param _amount amount of tokens
    /// @param _tokenAddress address of token contract
    /// @param _msgForSign hashed data 
    /// @param _signature signed data
    function payIn(
        uint _orderId,
        uint _amount, 
        address _tokenAddress,
        bytes32 _msgForSign, 
        bytes calldata _signature
    ) external {
        require(trustedSigner[_msgForSign.recover(_signature)][_tokenAddress], "bad signer");
        require(!orders[_orderId], "used order id");
        require(keccak256(abi.encode(
            _orderId,
            msg.sender,
            _amount,
            0, // <- direction
            chainId, 
            _tokenAddress
            )).toEthSignedMessageHash() == _msgForSign, "bad data in msgForSign");
        orders[_orderId] = true;
        emit PayInEvent(msg.sender, _tokenAddress, _orderId);
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        IERC20(_tokenAddress).burn(address(this), _amount);            
    }

    /// @dev transfer tokens to user
    /// @param _orderId unique order id
    /// @param _amount amount of tokens
    /// @param _tokenAddress address of token contract
    /// @param _msgForSign hashed data 
    /// @param _signature signed data
    function payOut(
        uint _orderId,
        uint _amount,
        address _tokenAddress,
        bytes32 _msgForSign, 
        bytes calldata _signature
    ) external {
        require(trustedSigner[_msgForSign.recover(_signature)][_tokenAddress], "bad signer");
        require(!orders[_orderId], "used order id");
        require(keccak256(abi.encode(
            _orderId,
            msg.sender,
            _amount,
            1, // <-- direction
            chainId,
            _tokenAddress
            )).toEthSignedMessageHash() == _msgForSign, "bad data in msgForSign");
        orders[_orderId] = true;
        emit PayOutEvent(msg.sender, _tokenAddress, _orderId);
        IERC20(_tokenAddress).mint(msg.sender, _amount);
    }

    //////////////////////////////////////
    ////   Admin functions    ////////////
    //////////////////////////////////////

    /// @dev set backed signer for token contract
    /// @notice only Owner can call this function
    /// @param signer address of signer
    /// @param tokenAddress address of token 
    /// @param isValid true or false
    function setSigner(address signer, address tokenAddress, bool isValid) external onlyOwner {
        trustedSigner[signer][tokenAddress] = isValid;
        emit SignerUpdated(signer, tokenAddress, isValid);
    }

}
