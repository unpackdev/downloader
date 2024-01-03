// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

contract Main is ERC721Holder, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;
    enum TokenType { Erc20, Erc721 }

    struct TokenDeposit {
        address _tokenAddress;
        uint256 _value;
        TokenType _type;
    }

    struct TokenDepositWithDecimals {
        address _tokenAddress;
        uint256 _value;
        TokenType _type;
        uint8 _decimals;
    }

    event Deposit(
        address _contractAddress,
        uint256 _value,
        uint _type,
        uint256 _vaultId
    );

    event Withdraw(
        uint256 _vaultId,
        address _to
    );

    // global counter of vaultIds
    Counters.Counter private _globalIndex;

    // constants
    uint constant MAX = uint(0) - uint(1);
    uint constant DUST_WITHDRAWAL_TIMESTAMP = 1635379200;

    // vaultId<>tokens
    mapping (uint256 => TokenDeposit[]) _VaultIdToDeposits;

    // vaultIds
    uint256[] _vaults;

    // owner<>vaultId
    mapping(address => uint256) _OwnerToVaultId;
    mapping(uint256 => address) _VaultIdToOwner;


    bool public isGameActive = true;
    bool public isEmergencyPlugPlugged = false;
    uint public gameEndTimestamp;

    uint256 private _random;

    constructor (uint256 timestamp) public {
        gameEndTimestamp = timestamp;
    }

    // deposit
    function _depositERC20(address[] memory erc20Addresses, uint256[] memory erc20Values) private   {
        require(erc20Addresses.length == erc20Values.length, "both array need to be same length");

        for (uint i = 0; i< erc20Addresses.length; i++) {
            IERC20(erc20Addresses[i]).safeTransferFrom(msg.sender, address(this), erc20Values[i]);
            TokenDeposit memory entry = TokenDeposit(erc20Addresses[i], erc20Values[i], TokenType.Erc20);
            _VaultIdToDeposits[_getUserVaultId()].push(entry);
            emit Deposit(erc20Addresses[i], erc20Values[i], 0, _getUserVaultId());
        }
    }

    function _depositERC721(address[] memory erc721Addresses, uint256[] memory erc721TokenIds) private {
        require(erc721Addresses.length == erc721TokenIds.length, "both array need to be same length");

        for (uint i = 0; i< erc721Addresses.length; i++) {
            IERC721(erc721Addresses[i]).safeTransferFrom(msg.sender, address(this), erc721TokenIds[i]);
            TokenDeposit memory entry = TokenDeposit(erc721Addresses[i], erc721TokenIds[i], TokenType.Erc721);
            _VaultIdToDeposits[_getUserVaultId()].push(entry);
            emit Deposit(erc721Addresses[i], erc721TokenIds[i], 1, _getUserVaultId());
        }
    }

    function deposit(
        address[] calldata erc20Addresses, uint256[] calldata erc20Values,
        address[] calldata erc721Addresses, uint256[] calldata erc721TokenIds
    ) external gameActive nonReentrant {
        require(erc721Addresses.length > 0 || erc20Addresses.length > 0, "at least one token needs to be deposited");

        if (erc721Addresses.length > 0) {
            _depositERC721(erc721Addresses, erc721TokenIds);
        }
        if (erc20Addresses.length > 0) {
            _depositERC20(erc20Addresses, erc20Values);
        }

        _endGameMaybe();
    }

    function _getUserVaultId() private returns(uint256) {
        // new user
        if (_OwnerToVaultId[msg.sender] == 0) {
            _globalIndex.increment();
            uint256 current = _globalIndex.current();
            _OwnerToVaultId[msg.sender] = current;
            _VaultIdToOwner[current] = msg.sender;
            _vaults.push(current);
        }
        return _OwnerToVaultId[msg.sender];
    }

    function _getMiddleAddress() private view returns (address) {
        uint256 middleVaultId;
        if (_vaults.length == 0) {
            return address(0);
        }
        if (_vaults.length.mod(2) != 0) {
            middleVaultId = _vaults[_vaults.length.sub(1).div(2)];
        } else {
            middleVaultId = _vaults[_vaults.length.div(2)];
        }
        return _VaultIdToOwner[middleVaultId];
    }

    function _endGameMaybe() private {
        if(block.timestamp > gameEndTimestamp) {
            isGameActive = false;
            address _middleAddress = _getMiddleAddress();
            _random = uint256(keccak256(abi.encodePacked(blockhash(block.number), _middleAddress)));
        }
    }

    modifier gameActive {
      require(isGameActive == true, "game is not active");
      _;
    }

    modifier gameOver {
      require(isGameActive == false, "game is still active");
      _;
    }

    function withdraw() external gameOver nonReentrant {
        require(_OwnerToVaultId[msg.sender] > 0, "must be a player");

        if (isEmergencyPlugPlugged) {
            uint256 vaultId = _OwnerToVaultId[msg.sender];
            _withdraw(vaultId, msg.sender);
            emit Withdraw(vaultId, msg.sender);
        } else {
            (uint256 vaultId, uint256 vaultIndex) = _getRandomVaultIdIndex();
            _deleteVaultAtIndex(vaultIndex);
            _withdraw(vaultId, msg.sender);
            emit Withdraw(vaultId, msg.sender);
        }
    }

    function _withdraw(uint256 vaultId, address beneficiary) private {

        for (uint i = 0; i< _VaultIdToDeposits[vaultId].length; i++) {
            TokenDeposit memory entry = _VaultIdToDeposits[vaultId][i];
            if (entry._type == TokenType.Erc721) {
                IERC721(entry._tokenAddress).safeTransferFrom(address(this), beneficiary, entry._value);
            }
            if (entry._type == TokenType.Erc20) {
                IERC20(entry._tokenAddress).safeTransfer(beneficiary, entry._value);
            }
        }

        // cleanup
        delete _VaultIdToDeposits[vaultId];
        delete _OwnerToVaultId[beneficiary];
        delete _VaultIdToOwner[vaultId];
    }

    function _deleteVaultAtIndex(uint index) internal {
        require(index < _vaults.length);
        _vaults[index] = _vaults[_vaults.length-1];
        _vaults.pop();
    }

    function _getRandomVaultIdIndex() private view returns(uint256, uint256) {
        uint256 randomIndex = _getRandom(_random, _vaults.length);
        return (_vaults[randomIndex], randomIndex);
    }

    function _getRandom(uint256 seed, uint256 upperBound) private pure returns(uint256) {
        return seed / (MAX / upperBound);
    }

    function getVaultIdCounter() external view returns(uint256) {
        return _globalIndex.current();
    }

    function isUserPlayer(address userAddress) external view returns(bool) {
        return _OwnerToVaultId[userAddress] > 0;
    }

    function getVaultDepositsOfOwner(address owner) external view returns (TokenDepositWithDecimals[] memory) {
        uint256 vaultId = _OwnerToVaultId[owner];
        TokenDepositWithDecimals[] memory tokenList = new TokenDepositWithDecimals[](_VaultIdToDeposits[vaultId].length);
        for (uint i = 0; i< _VaultIdToDeposits[vaultId].length; i++) {
            TokenDeposit memory tokenDeposit = _VaultIdToDeposits[vaultId][i];
            uint8 decimals = 0;
            if (tokenDeposit._type == TokenType.Erc20) {
                decimals = IERC20Decimals(tokenDeposit._tokenAddress).decimals();
            }
            tokenList[i] = TokenDepositWithDecimals(tokenDeposit._tokenAddress, tokenDeposit._value, tokenDeposit._type, decimals);
        }
        return tokenList;
    }

    function emergencyPlug() external onlyOwner {
        isGameActive = false;
        isEmergencyPlugPlugged = true;
    }

    function dust(address tokenAddress, uint256 value, TokenType tokenType) external onlyOwner {
        require(block.timestamp > DUST_WITHDRAWAL_TIMESTAMP, "try again later");
        if (tokenType == TokenType.Erc721) {
            IERC721(tokenAddress).safeTransferFrom(address(this), msg.sender, value);
        }
        if (tokenType == TokenType.Erc20) {
            IERC20(tokenAddress).safeTransfer(msg.sender, value);
        }
    }
}