// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./ERC721A.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ERC721Royalty.sol";
import "./ERC721URIStorage.sol";

//Interface
interface INFTLaunchPad {
    function getBrokerage(address currency) external view returns (int256);

    function brokerAddress() external view returns (address);

    function getPublicKey() external view returns (address);
}

contract NFTCollection is ERC721A, ERC2981, Ownable {
    uint256 public maxSupply; //Set the maximum supply
    string baseURI; //Set the Base URI
    string baseURISuffix = ".json"; //Set the base URI Suffix
    string public contractURI; //Set the contract URI
    uint256 public whitelistedFee; //Set the whitelisted Fee
    uint256 public mintFee; //Set the mint Fee
    uint256 public maxQuantity; //Set the maximum quantity
    address public creator; //Address of Creator
    uint256 WhiteListStartTime; //Set the WhiteListStartTime
    uint256 WhiteListEndTime; //Set the WhiteListEndTime
    mapping(uint256 => bool) public proceedNonce;
    uint256 public constant DECIMAL_PRECISION = 100; //Set the Decimal Precision
    uint256 public tokenCounter; //Set the tokenCounter
    IERC20 public currency; //Set the address of currency
    INFTLaunchPad public launchpad; //Set the address of launchpad

    //Structs
    struct UintArgs {
        uint256 maxSupply;
        uint256 whitelistedFee;
        uint256 mintFee;
        uint256 maxQuantity;
        uint96 royalty;
        uint256 WhiteListStartTime;
        uint256 WhiteListEndTime;
    }

    struct StringArgs {
        string name;
        string symbol;
        string baseURI;
        string contractURI;
    }

    constructor(
        UintArgs memory _uints,
        address _creator,
        StringArgs memory _strings,
        address _currency
    ) ERC721A(_strings.name, _strings.symbol) {
        maxSupply = _uints.maxSupply;
        whitelistedFee = _uints.whitelistedFee;
        mintFee = _uints.mintFee;
        maxQuantity = _uints.maxQuantity;
        WhiteListStartTime = _uints.WhiteListStartTime;
        WhiteListEndTime = _uints.WhiteListEndTime;
        creator = _creator;
        baseURI = _strings.baseURI;
        contractURI = _strings.contractURI;
        currency = IERC20(_currency);
        launchpad = INFTLaunchPad(msg.sender);
        _setDefaultRoyalty(creator, _uints.royalty);
        _transferOwnership(creator);
    }

    /**
     *@dev Method to set whitelistedFee.
     *@notice This method will allow owner to set whitelistedFee.
     *@param _value whitelisted fee to be set in this method;
     */
    function setWhitelistedFee(uint256 _value) external onlyOwner {
        whitelistedFee = _value;
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    /**
     *@dev Method to set whitelistedFee.
     *@notice This method will allow owner to set mintFee.
     *@param _value mint Fee to be set in this method;
     */
    function setMintFee(uint256 _value) external onlyOwner {
        mintFee = _value;
    }

    /**
     *@dev Method to generate signer.
     *@notice This method is used to provide signer.
     *@param hash: Name of hash is used to generate the signer.
     *@param _signature: Name of _signature is used to generate the signer.
     @return Signer address.
    */
    function getSigner(bytes32 hash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
                ),
                v,
                r,
                s
            );
    }

    /**
     *@dev Method to get Brokerage.
     *@notice This method is used to get Brokerage.
     *@param _currency: address of Currency.
     */
    function _getBrokerage(address _currency) private view returns (uint) {
        int256 _brokerage = launchpad.getBrokerage(_currency);
        require(_brokerage != 0, "NFTCollection: Currency doesn't supported.");
        if (_brokerage < 0) {
            _brokerage = 0;
        }
        return uint(_brokerage);
    }

    /**
     *@dev Method to get PublicKey
     *@return It will return PublicKey
     */
    function _getPublicKey() private view returns (address) {
        return launchpad.getPublicKey();
    }

    /**
     *@dev Method to get Broker address
     *@return Return the address of broker
     */
    function _getBrokerAddress() private view returns (address) {
        return launchpad.brokerAddress();
    }

    /**
     *@dev Method to verify WhiteList user.
     *@notice This method is used to verify whitelist user.
     *@param whitelistUser: Address of whitelistUser.
     *@param nonce: nonce to be generated while minting.
     *@param _isWhiteListed: User is whitelisted or not.
     *@param _signature: _signature is used to generate the signer.
     *@return bool value if user is verified.
     */
    function verifyWhiteListUser(
        address whitelistUser,
        uint256 nonce,
        bool _isWhiteListed,
        bytes memory _signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                address(this),
                launchpad,
                whitelistUser,
                nonce,
                _isWhiteListed
            )
        );
        address verifiedUser = getSigner(hash, _signature);

        require(
            verifiedUser == _getPublicKey(),
            "NFTCollection: User is not verified!"
        );
        return _isWhiteListed;
    }

    /**
     *@dev Method to split the signature.
     *@param sig: Name of _signature is used to generate the signer.
     */
    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "NFTCollection: invalid signature length.");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function _sendNative(uint256 brokerage, uint256 _amount) private {
        if (brokerage > 0) {
            uint256 brokerageAmount = (_amount * uint256(brokerage)) /
                (100 * DECIMAL_PRECISION);
            payable(_getBrokerAddress()).transfer(brokerageAmount);
            uint256 remainingAmount = _amount - brokerageAmount;
            payable(creator).transfer(remainingAmount);
        } else {
            payable(creator).transfer(_amount);
        }
    }

    function _sendERC20(uint256 brokerage, uint256 _amount) private {
        require(
            currency.allowance(msg.sender, address(this)) >= _amount,
            "NFTCollection: Insufficient fund allowance"
        );
        if (brokerage > 0) {
            uint256 brokerageAmount = (_amount * uint256(brokerage)) /
                (100 * DECIMAL_PRECISION);
            currency.transferFrom(
                msg.sender,
                _getBrokerAddress(),
                brokerageAmount
            );
            uint256 remainingAmount = _amount - brokerageAmount;
            currency.transferFrom(msg.sender, address(this), remainingAmount);
        } else {
            currency.transferFrom(msg.sender, address(this), _amount);
        }
    }

    /**
     *@dev Method to mint the NFT.
     *@notice This method is used to mint the NFT.
     *@param _quantity: NFT quantity to be minted.
     *@param nonce: nonce to be generated while minting.
     *@param _signature: _signature is used to generate the signer.
     *@param _isWhiteListed: User is whitelisted or not.
     */
    function mint(
        uint256 _quantity,
        uint256 nonce,
        bytes calldata _signature,
        bool _isWhiteListed
    ) external payable {
        require(
            tokenCounter + _quantity <= maxSupply,
            "NFTCollection: Max supply must be greater!"
        );
        tokenCounter += _quantity;

        require(!proceedNonce[nonce], "NFTCollection: Nonce already proceed!");
        require(
            _quantity > 0 && _quantity <= maxQuantity,
            "NFTCollection: Max quantity reached"
        );

        bool WhiteListed = verifyWhiteListUser(
            msg.sender,
            nonce,
            _isWhiteListed,
            _signature
        );
        uint brokerage = _getBrokerage(address(currency));
        if (
            WhiteListed &&
            block.timestamp <= WhiteListStartTime &&
            WhiteListStartTime <= WhiteListEndTime
        ) {
            if (address(currency) == address(0)) {
                require(
                    msg.value >= whitelistedFee * _quantity,
                    "NFTCollection: Whitelisted amount is insufficient."
                );
                _sendNative(brokerage, msg.value);
            } else {
                _sendERC20(brokerage, whitelistedFee * _quantity);
            }
        } else {
            require(
                block.timestamp > WhiteListEndTime,
                "NFTCollection: Whitelist sale not ended yet."
            );
            if (address(currency) == address(0)) {
                require(
                    msg.value >= mintFee * _quantity,
                    "NFTCollection:  amount is insufficient."
                );
                _sendNative(brokerage, msg.value);
            } else {
                _sendERC20(brokerage, mintFee * _quantity);
            }
        }

        _mint(msg.sender, _quantity);

        proceedNonce[nonce] = true;
    }

    /**
     *@dev Method to burn NFT.
     *@param tokenId: tokenId to be burned.
     */
    function burn(uint256 tokenId) external {
        require(
            ownerOf(tokenId) == msg.sender,
            "NFTCollection: Caller is not the token owner"
        );
        _burn(tokenId, false);
    }

    /**
     *@dev Method to mint by only owner.
     *@notice This method will allow owner to mint.
     *@param _quantity: NFT quantity to be minted.
     */
    function mintByOwner(uint256 _quantity) external onlyOwner {
        require(
            tokenCounter + _quantity <= maxSupply,
            "NFTCollection: Max supply must be greater!"
        );
        tokenCounter += _quantity;
        _mint(msg.sender, _quantity);
    }

    /**
     *@dev Method to withdraw ERC20 token.
     *@notice This method will allow only owner to withdraw ERC20 token.
     *@param _receiver: address of receiver
     */
    function withdrawERC20Token(address _receiver) external onlyOwner {
        require(
            currency.balanceOf(address(this)) > 0,
            "NFTCollection: Insufficient fund"
        );
        currency.transfer(_receiver, currency.balanceOf(address(this)));
    }

    /**
     *@dev Method to withdraw native currency.
     *@notice This method will allow only owner to withdraw currency.
     *@param _receiver: address of receiver
     */

    function withdrawBNB(address _receiver) external onlyOwner {
        payable(_receiver).transfer(balanceOf(address(this)));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _baseURISuffix() internal view virtual returns (string memory) {
        return baseURISuffix;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(baseURI, _toString(tokenId), baseURISuffix)
                )
                : "";
    }

}
