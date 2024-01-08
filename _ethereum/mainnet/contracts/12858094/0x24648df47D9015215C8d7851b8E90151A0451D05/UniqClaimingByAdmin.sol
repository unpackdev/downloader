// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";

contract UniqClaimingByAdmin is Ownable {
    /// ----- VARIABLES ----- ///

    /// Settings

    /// @dev Claiming Price
    uint256 internal _standardClaimingPrice;

    /// @dev Owner Changing price
    uint256 internal _standardOwnerChangingPrice;

    /// @dev Verification price
    uint256 internal _standardPriceForVerification;

    /// @dev address of ERC20 token
    address internal _ERC20tokenAddress;

    /// NFT Contracts

    /// @dev Contract Addresses Accepted By Uniqly
    mapping(address => bool) internal _acceptedContracts;

    /// @dev Price for claiming in Native ERC20 token
    mapping(address => uint256) internal _pricesForClaiming;

    /// @dev Change Onwer
    mapping(address => uint256) internal _pricesForOwnerChanging;

    /// @dev isBurable
    mapping(address => bool) internal _isBurnable;

    /// Token

    /// @dev Returns true if token was claimed
    mapping(address => mapping(uint256 => bool)) internal _isTokenClaimed;

    /// @dev Claimed ids of contract
    mapping(address => uint256[]) internal _claimedIds;

    /// @dev Owners addresses Array
    mapping(address => mapping(uint256 => mapping(uint256 => address)))
        internal _ownersAddresses;

    /// @dev Owners array count
    mapping(address => mapping(uint256 => uint256)) internal _ownersCount;

    /// Name verification

    /// @dev Nonce for verification
    mapping(uint256 => bool) internal _isNonceRedeemed;

    /// @dev Addresses owners
    mapping(address => string) internal _addressesOwners;

    /// @dev Is onwer verified
    mapping(address => bool) internal _isAddressesOwnerVerified;

    /// ----- EVENTS ----- ///

    event Claim(
        address indexed _contractAddress,
        address indexed _claimer,
        uint256 indexed _tokenId,
        bytes _verificationStatus,
        string _claimersName
    );

    event ChangeOwner(
        address indexed _contractAddress,
        uint256 indexed _id,
        address _newOwner,
        address indexed _prevOwner,
        string _newOwnersName
    );

    event PayedForClaim(
        address indexed _claimer,
        address indexed _contractAddress,
        uint256 indexed _tokenId
    );

    event RequestedVerification(address indexed _requester, string _name);

    /// ----- VIEWS ----- ///

    /// @notice Returns true if token was claimed
    function isTokenClaimed(address _address, uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return _isTokenClaimed[_address][_tokenId];
    }

    /// @notice Returns true for authorized contract addresses
    function isContractAuthorized(address _address)
        external
        view
        returns (bool)
    {
        return _acceptedContracts[_address];
    }

    /// @notice Returns last owners address, name and verification status
    function getLastOwnerOf(address _address, uint256 _id)
        external
        view
        returns (
            address,
            string memory,
            bool
        )
    {
        uint256 len = _ownersCount[_address][_id] - 1;
        address ownerAddress = _ownersAddresses[_address][_id][len];
        return (
            ownerAddress,
            _addressesOwners[ownerAddress],
            _isAddressesOwnerVerified[ownerAddress]
        );
    }

    /// @notice Returns true when nonce was redeemed
    function isNonceRedeemed(uint256 _nonce) external view returns (bool) {
        return _isNonceRedeemed[_nonce];
    }

    /// @notice Returns owners count of token
    function getOwnersCountOfToken(address _address, uint256 _id)
        external
        view
        returns (uint256)
    {
        return (_ownersCount[_address][_id]);
    }

    /// @notice Returns owners name and verification status
    function getAddressOwnerInfo(address _address)
        external
        view
        returns (string memory, bool)
    {
        bytes memory bts = bytes(_addressesOwners[_address]);
        require(bts.length != 0, "Address not used yet");
        return (
            _addressesOwners[_address],
            _isAddressesOwnerVerified[_address]
        );
    }

    /// @notice Returns address and name of token owner by position in array
    function getOwnerOfTokenByPosition(
        address _address,
        uint256 _id,
        uint256 _position
    ) external view returns (address, string memory) {
        address ownerAddress = _ownersAddresses[_address][_id][_position];
        return (ownerAddress, _addressesOwners[ownerAddress]);
    }

    /// @notice Returns all token holders names
    function getAllTokenHoldersNamesHistory(address _address, uint256 _id)
        external
        view
        returns (string[] memory)
    {
        uint256 len = _ownersCount[_address][_id];
        if (len == 0) {
            return new string[](0);
        }
        string[] memory res = new string[](len);
        uint256 index;
        for (index = 0; index < len; index++) {
            res[index] = _addressesOwners[
                _ownersAddresses[_address][_id][index]
            ];
        }
        return res;
    }

    /// @notice Returns all token holders addresses
    function getAllTokenHoldersAddressesHistory(address _address, uint256 _id)
        external
        view
        returns (address[] memory)
    {
        uint256 len = _ownersCount[_address][_id];
        if (len == 0) {
            return new address[](0);
        }
        address[] memory res = new address[](len);
        uint256 index;
        for (index = 0; index < len; index++) {
            res[index] = _ownersAddresses[_address][_id][index];
        }
        return res;
    }

    /// @notice Returns all claimed ids of selected collection
    function getClaimedIdsOfCollection(address _address)
        external
        view
        returns (uint256[] memory)
    {
        uint256 len = _claimedIds[_address].length;
        if (len == 0) {
            return new uint256[](0);
        }
        uint256[] memory res = new uint256[](len);
        uint256 index;
        for (index = 0; index < len; index++) {
            res[index] = _claimedIds[_address][index];
        }
        return res;
    }

    /// @notice Returns how many items of collection was claimed
    function getClaimedCountOf(address _address)
        external
        view
        returns (uint256)
    {
        return _claimedIds[_address].length;
    }

    /// @notice Returns Claiming Standard price
    function getStandardClaimingPrice() external view returns (uint256) {
        return _standardClaimingPrice;
    }

    /// @notice Returns Claiming Price For selected contract
    function getClaimingPriceForContract(address _address)
        external
        view
        returns (uint256)
    {
        return
            _getCorrectPrice(
                _pricesForClaiming[_address],
                _standardClaimingPrice
            );
    }

    /// @notice Returns Holders Change Rate For selected contract
    function getChangeOwnerPriceForContract(address _address)
        external
        view
        returns (uint256)
    {
        return
            _getCorrectPrice(
                _pricesForOwnerChanging[_address],
                _standardOwnerChangingPrice
            );
    }

    /// @notice Returns Standard Price For Verification
    function getPriceForVerification() external view returns (uint256) {
        return _standardPriceForVerification;
    }

    /// @notice Returns true for burnable tokens in contract
    function isBurnable(address _address) external view returns (bool) {
        return _isBurnable[_address];
    }

    /// @notice Returns sum of prices for verificagtion and claim
    function getPriceForMintAndVerify(address _contractAddress)
        external
        view
        returns (uint256)
    {
        uint256 claimingPrice = _getCorrectPrice(
            _pricesForClaiming[_contractAddress],
            _standardClaimingPrice
        );
        uint256 sumPrice = claimingPrice + _standardPriceForVerification;
        return sumPrice;
    }

    /// ----- PUBLIC METHODS ----- ///

    /// @notice Used for verification
    function getMessageHashForOwnerChange(
        address _address,
        string memory _claimersName,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address, _claimersName, _nonce));
    }

    /// @notice Pays For Claim
    function payForClaim(address _contractAddress, uint256 _tokenId) external {
        require(
            _acceptedContracts[_contractAddress],
            "Contract address is not authorized"
        );
        uint256 claimingPrice = _getCorrectPrice(
            _pricesForClaiming[_contractAddress],
            _standardClaimingPrice
        );
        if (claimingPrice != 0) {
            IERC20 nativeToken = IERC20(_ERC20tokenAddress);
            require(
                nativeToken.transferFrom(
                    msg.sender,
                    address(this),
                    claimingPrice
                )
            );
        }
        emit PayedForClaim(msg.sender, _contractAddress, _tokenId);
    }

    /// @notice Claim Function
    function claimByAdmin(
        address _contractAddress,
        uint256 _tokenId,
        string memory _claimersName,
        bool _isVerified,
        address _claimer,
        string memory _verifyStatus
    ) external onlyOwner {
        require(
            _acceptedContracts[_contractAddress],
            "Contract address is not authorized"
        );
        require(
            !_isTokenClaimed[_contractAddress][_tokenId],
            "Can't be claimed again"
        );
        IERC721 token = IERC721(_contractAddress);
        require(
            token.ownerOf(_tokenId) == _claimer,
            "Claimer needs to own this token"
        );

        if (_isBurnable[_contractAddress]) {
            IERC721Burnable(_contractAddress).burn(_tokenId);
        } else {
            token.transferFrom(_claimer, address(this), _tokenId);
        }

        _isTokenClaimed[_contractAddress][_tokenId] = true;
        _claimedIds[_contractAddress].push(_tokenId);
        _ownersAddresses[_contractAddress][_tokenId][0] = _claimer;

        if (!_isAddressesOwnerVerified[_claimer]) {
            _addressesOwners[_claimer] = _claimersName;
            _isAddressesOwnerVerified[_claimer] = _isVerified;
        }


        _ownersCount[_contractAddress][_tokenId]++;
        emit Claim(_contractAddress, _claimer, _tokenId, bytes(_verifyStatus), _claimersName);
    }

    /// @notice Change Onwer
    function changeOwner(
        address _contractAddress,
        uint256 _tokenId,
        string memory _newOwnersName,
        address _newOwnerAddress
    ) external {
        require(_isTokenClaimed[_contractAddress][_tokenId], "Not claimed yet");

        uint256 len = _ownersCount[_contractAddress][_tokenId];
        address ownerAddress = _ownersAddresses[_contractAddress][_tokenId][
            len - 1
        ];

        require(ownerAddress == msg.sender, "Not owner");

        uint256 changingPrice = _getCorrectPrice(
            _pricesForOwnerChanging[_contractAddress],
            _standardOwnerChangingPrice
        );
        if (changingPrice != 0) {
            IERC20 nativeToken = IERC20(_ERC20tokenAddress);
            require(
                nativeToken.transferFrom(
                    msg.sender,
                    address(this),
                    changingPrice
                )
            );
        }
        _ownersAddresses[_contractAddress][_tokenId][len] = _newOwnerAddress;

        if (!_isAddressesOwnerVerified[_newOwnerAddress]) {
            _addressesOwners[_newOwnerAddress] = _newOwnersName;
        }

        _ownersCount[_contractAddress][_tokenId]++;
        emit ChangeOwner(
            _contractAddress,
            _tokenId,
            _newOwnerAddress,
            msg.sender,
            _newOwnersName
        );
    }

    /// @notice Verify Owner
    function verifyOwner(
        string memory _claimersName,
        uint256 _nonce,
        bytes memory _signature
    ) external {
        require(
            verifySignForAuthOwner(
                msg.sender,
                _claimersName,
                _nonce,
                _signature
            ),
            "Signature is not valid"
        );
        // require(!_isAddressesOwnerVerified[msg.sender], "Already verified");
        require(!_isNonceRedeemed[_nonce], "Nonce redeemed");
        _addressesOwners[msg.sender] = _claimersName;
        _isAddressesOwnerVerified[msg.sender] = true;
        _isNonceRedeemed[_nonce] = true;
    }

    /// @notice Takes a fee for verification
    function requestVerification(string memory _nameToVerify) external {
        IERC20 nativeToken = IERC20(_ERC20tokenAddress);
        require(
            nativeToken.transferFrom(
                msg.sender,
                address(this),
                _standardPriceForVerification
            )
        );
        require(
            !_isAddressesOwnerVerified[msg.sender],
            "Address is already verified"
        );
        _addressesOwners[msg.sender] = _nameToVerify;
        emit RequestedVerification(msg.sender, _nameToVerify);
    }

    /// @notice Takes a fee for verification and pays for claim
    function payForClaimAndVerification(
        string memory _nameToVerify,
        address _contractAddress,
        uint256 _tokenId
    ) external {
        require(
            !_isAddressesOwnerVerified[msg.sender],
            "Address is already verified"
        );
        require(
            _acceptedContracts[_contractAddress],
            "Contract address is not authorized"
        );
        IERC20 nativeToken = IERC20(_ERC20tokenAddress);

        uint256 claimingPrice = _getCorrectPrice(
            _pricesForClaiming[_contractAddress],
            _standardClaimingPrice
        );
        uint256 sumPrice = claimingPrice + _standardPriceForVerification;

        if (sumPrice > 0) {
            require(
                nativeToken.transferFrom(msg.sender, address(this), sumPrice)
            );
        }

        _addressesOwners[msg.sender] = _nameToVerify;

        emit PayedForClaim(msg.sender, _contractAddress, _tokenId);
        emit RequestedVerification(msg.sender, _nameToVerify);
    }

    /// ----- OWNER METHODS ----- ///
    constructor(
        uint256 _standardPriceForClaiming,
        uint256 _standardVerificationPrice,
        uint256 _standardPriceForOwnerChanging,
        address _nativeTokenAddress
    ) {
        _standardClaimingPrice = _standardPriceForClaiming;
        _standardPriceForVerification = _standardVerificationPrice;
        _standardOwnerChangingPrice = _standardPriceForOwnerChanging;
        _ERC20tokenAddress = _nativeTokenAddress;
    }

    /// @notice Change verification price
    function setVerificationPrice(uint256 _newPrice) external onlyOwner {
        _standardPriceForVerification = _newPrice;
    }

    /// @notice Verify owner by admin
    function verifyByAdmin(
        address _userAddress,
        string memory _newName,
        bool _isVerifyed
    ) external onlyOwner {
        _addressesOwners[_userAddress] = _newName;
        _isAddressesOwnerVerified[_userAddress] = _isVerifyed;
    }

    /// @notice Change erc20 token using for payments
    function setErc20Token(address _contractAddress) external onlyOwner {
        _ERC20tokenAddress = _contractAddress;
    }

    /// @notice Contract settings
    /// @param _claimingPrice Set to 1 if you want to use Standard Claiming Price
    /// @param _changeOwnerPrice Set to 1 if you want to use Stanrad Owner Changing Price
    function setContractAtributes(
        address _address,
        bool _enable,
        uint256 _claimingPrice,
        uint256 _changeOwnerPrice,
        bool _isBurnble
    ) external onlyOwner {
        _acceptedContracts[_address] = _enable;
        _pricesForClaiming[_address] = _claimingPrice;
        _pricesForOwnerChanging[_address] = _changeOwnerPrice;
        _isBurnable[_address] = _isBurnble;
    }

    /// @notice Edit standard price for claiming
    function editStandardClaimingPrice(uint256 _price) external onlyOwner {
        _standardClaimingPrice = _price;
    }

    /// @notice Edit standard price for claiming
    function editStandardChangeOwnerPrice(uint256 _price) external onlyOwner {
        _standardOwnerChangingPrice = _price;
    }

    /// @notice Withdraw/rescue erc20 tokens to owners address
    function withdrawERC20(address _address) external onlyOwner {
        uint256 val = IERC20(_address).balanceOf(address(this));
        Ierc20(_address).transfer(msg.sender, val);
    }

    /// @notice Owner change by admin
    function changeOwnerByAdmin(
        address _address,
        uint256 _id,
        address _newOwnerAddress,
        string memory _newOwnersName,
        bool _verificationStatus
    ) external onlyOwner {
        require(_isTokenClaimed[_address][_id], "Not claimed yet");
        uint256 len = _ownersCount[_address][_id];
        _ownersAddresses[_address][_id][len] = _newOwnerAddress;
        _addressesOwners[_newOwnerAddress] = _newOwnersName;
        _isAddressesOwnerVerified[_newOwnerAddress] = _verificationStatus;
        emit ChangeOwner(
            _address,
            _id,
            _newOwnerAddress,
            address(0),
            _newOwnersName
        );
    }

    /// ----- PRIVATE METHODS ----- ///

    /// @dev Return second argument when first equals 1
    function _getCorrectPrice(uint256 _priceForContract, uint256 _standardPrice)
        internal
        pure
        returns (uint256)
    {
        if (_priceForContract == 1) {
            return _standardPrice;
        } else return _priceForContract;
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verifySignForAuthOwner(
        address _address,
        string memory _claimersName,
        uint256 _nonce,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHashForOwnerChange(
            _address,
            _claimersName,
            _nonce
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
}

interface Ierc20 {
    function transfer(address, uint256) external;
}

interface IERC721Burnable {
    function burn(uint256) external;
}
