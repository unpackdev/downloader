// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC721.sol";
import "./IERC20.sol";
import "./draft-EIP712.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./Counters.sol";

contract FeudalzStaking is EIP712, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    
    IERC20 goldz = IERC20(0x7bE647634A942e73F8492d15Ae492D867Ce5245c);

    struct StakedContract {
        bool active;
        IERC721 instance;
    }

    mapping(address => mapping(address => EnumerableSet.UintSet)) addressToStakedTokensSet;
    mapping(address => mapping(uint => address)) contractTokenIdToOwner;
    mapping(address => mapping(uint => uint)) contractTokenIdToStakedTimestamp;
    mapping(address => StakedContract) public contracts;
    mapping(address => Counters.Counter) addressToNonce;
    mapping(address => uint) public accountToLastWithdraw;
    mapping(address => uint) public accountToLastWithdrawAmount;
    
    EnumerableSet.AddressSet activeContracts;
    address _signerAddress;
    
    event Stake(uint tokenId, address contractAddress, address owner);
    event Unstake(uint tokenId, address contractAddress, address owner);
    event Withdraw(address owner, uint amount);

    modifier ifContractExists(address contractAddress) {
        require(activeContracts.contains(contractAddress), "contract does not exists");
        _;
    }

    modifier incrementNonce() {
        addressToNonce[msg.sender].increment();
        _;
    }

    constructor() EIP712("FeudalzStaking", "1.0.0") {}

    function stake(address contractAddress, uint[] memory tokenIds) external incrementNonce {
        StakedContract storage _contract = contracts[contractAddress];
        require(_contract.active, "token contract is not active");

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];

            // Assign token to his owner
            contractTokenIdToOwner[contractAddress][tokenId] = msg.sender;

            // Transfer token to this smart contract
            _contract.instance.safeTransferFrom(msg.sender, address(this), tokenId);

            // Add this token to user staked tokens
            addressToStakedTokensSet[contractAddress][msg.sender].add(tokenId);

            // Save stake timestamp
            contractTokenIdToStakedTimestamp[contractAddress][tokenId] = block.timestamp;

            emit Stake(tokenId, contractAddress, msg.sender);
        }
    }

    function unstake(address contractAddress, uint[] memory tokenIds) external incrementNonce ifContractExists(contractAddress) {
        StakedContract storage _contract = contracts[contractAddress];

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            require(addressToStakedTokensSet[contractAddress][msg.sender].contains(tokenId), "token is not staked");

            // Remove owner of this token
            delete contractTokenIdToOwner[contractAddress][tokenId];

            // Transfer token to his owner
            _contract.instance.safeTransferFrom(address(this), msg.sender, tokenId);

            // Remove this token from user staked tokens
            addressToStakedTokensSet[contractAddress][msg.sender].remove(tokenId);

            // Remove stake timestamp
            delete contractTokenIdToStakedTimestamp[contractAddress][tokenId];

            emit Unstake(tokenId, contractAddress, msg.sender);
        }
    }

    function stakedTokensOfOwner(address contractAddress, address owner) external view ifContractExists(contractAddress) returns (uint[] memory) {
        EnumerableSet.UintSet storage userTokens = addressToStakedTokensSet[contractAddress][owner];

        uint[] memory tokenIds = new uint[](userTokens.length());

        for (uint i = 0; i < userTokens.length(); i++) {
            tokenIds[i] = userTokens.at(i);
        }

        return tokenIds;
    }

    function stakedTokenTimestamp(address contractAddress, uint tokenId) external view ifContractExists(contractAddress) returns (uint) {
        return contractTokenIdToStakedTimestamp[contractAddress][tokenId];
    }

    function withdrawGoldz(uint amount, bytes calldata signature) external {
        require(_signerAddress == recoverAddress(msg.sender, amount, accountNonce(msg.sender), signature), "invalid signature");
        goldz.transferFrom(address(this), msg.sender, amount);
        addressToNonce[msg.sender].increment();
        accountToLastWithdraw[msg.sender] = block.timestamp;
        accountToLastWithdrawAmount[msg.sender] = amount;
        emit Withdraw(msg.sender, amount);
    }

    function addContract(address contractAddress) public onlyOwner {
        contracts[contractAddress].active = true;
        contracts[contractAddress].instance = IERC721(contractAddress);
        activeContracts.add(contractAddress);
    }

    function updateContract(address contractAddress, bool active) public onlyOwner ifContractExists(contractAddress) {
        require(activeContracts.contains(contractAddress), "contract not added");
        contracts[contractAddress].active = active;
    }

    function accountNonce(address accountAddress) public view returns (uint) {
        return addressToNonce[accountAddress].current();
    }
    
    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }

    function _hash(address account, uint amount, uint nonce) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("MyGoldz(uint256 amount,address account,uint256 nonce)"),
                        amount,
                        account,
                        nonce
                    )
                )
            );
    }

    function recoverAddress(address account, uint amount, uint nonce, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, amount, nonce), signature);
    }

    function onERC721Received(address operator, address, uint256, bytes calldata) external returns(bytes4) {
        require(operator == address(this), "token must be staked over stake method");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}