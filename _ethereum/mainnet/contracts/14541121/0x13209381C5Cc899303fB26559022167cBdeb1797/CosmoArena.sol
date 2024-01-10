/***********************

  ＣＯＳＭＯＰＯＬＩＴＹ 🪐
    -- METEOROIDS --
    
    cosmopolity.art

************************/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ECDSA.sol";
import "./ERC721.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Address.sol";
import "./Cosmopolity.sol";
import "./Strings.sol";

contract CosmoArena is
    IERC721MetadataUpgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    using ECDSA for bytes32;

    bool public mintable;
    address payable public feeAddress;
    uint256 public publicMintCount;
    string public baseURI;
    uint256 public currentPrice;
    string public contractURI;
    address public stylizerContractAddress;
    address guarantorAddress;
    uint256 public publicMintCeiling;

    mapping(address => mapping(string => bool)) public originClaimed;

    struct OriginTokenInfo {
        address originContractAddress;
        string originTokenId;
    }

    // duplicate initial token info for quick lookup on the client side
    mapping(uint256 => OriginTokenInfo) public originByRockId;

    function initialize(
        string memory name,
        string memory symbol,
        address payable _feeAddress,
        string memory initBaseURI
    ) public initializer {
        __ERC721_init(name, symbol);
        __Ownable_init();
        feeAddress = _feeAddress;
        baseURI = initBaseURI;

        publicMintCount = 0;
        currentPrice = 0.0 ether;
        publicMintCeiling = 50000;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _getMessageHash(
        address _owner,
        address _styleTokenContractAddress,
        string memory _styleTokenId,
        uint256 _nonce
    ) public pure returns (bytes32) {
        string memory _message = "STYLE_TOKEN_OK_TO_USE";
        return
            keccak256(
                abi.encodePacked(
                    _message,
                    _owner,
                    _styleTokenContractAddress,
                    _styleTokenId,
                    _nonce
                )
            );
    }

    function _verify(
        address _owner,
        address _styleTokenContractAddress,
        string memory _styleTokenId,
        uint256 _nonce,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 messageHash = _getMessageHash(
            _owner,
            _styleTokenContractAddress,
            _styleTokenId,
            _nonce
        );
        return
            messageHash.toEthSignedMessageHash().recover(signature) ==
            guarantorAddress;
    }

    function claimOne(
        address to,
        address originContractAddress,
        string memory originTokenId,
        uint256 nonce,
        bytes memory signature
    ) public payable {
        require(
            _verify(
                msg.sender,
                originContractAddress,
                originTokenId,
                nonce,
                signature
            ),
            "Invalid signature"
        );
        publicMintCount++;

        uint256 newRockId = 200 + publicMintCount;
        _mintRock(to, originContractAddress, originTokenId, newRockId);
    }

    function _mintRock(
        address to,
        address originContractAddress,
        string memory originTokenId,
        uint256 newRockId
    ) internal {
        require(
            totalSupply() + 1 <= publicMintCeiling,
            "Current total mint limit reached."
        );
        require(
            !originClaimed[originContractAddress][originTokenId],
            "The origin token is already used for claiming."
        );
        _assignOrigin(originContractAddress, originTokenId, newRockId);
        _mint(to, newRockId);
    }

    function _assignOrigin(
        address originContractAddress,
        string memory originTokenId,
        uint256 newRockId
    ) internal {
        originByRockId[newRockId] = OriginTokenInfo(
            originContractAddress,
            originTokenId
        );
        originClaimed[originContractAddress][originTokenId] = true;
    }

    function tokenExists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /***** Owner Operations *****/
    function ownerSetBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function ownerSetFeeAddress(address payable _newAddress) public onlyOwner {
        feeAddress = _newAddress;
    }

    function ownerSetMintable(bool _mintable) public onlyOwner {
        mintable = _mintable;
    }

    function ownerSetStylizerContractAddress(address _addr) public onlyOwner {
        stylizerContractAddress = _addr;
    }

    function ownerWithdrawETH() public onlyOwner {
        Address.sendValue(feeAddress, address(this).balance);
    }

    function ownerSetCurrentPrice(uint256 _price) public onlyOwner {
        currentPrice = _price;
    }

    function ownerSetContractURI(string memory _newContractURI)
        public
        onlyOwner
    {
        contractURI = _newContractURI;
    }

    function ownerSetPublicMintCeiling(uint256 _newMintCeiling)
        public
        onlyOwner
    {
        publicMintCeiling = _newMintCeiling;
    }

    function ownerSetGuarantorAddress(address _addr) public onlyOwner {
        guarantorAddress = _addr;
    }

    function ownerBatchMirrorMint(
        address cosContractAdrress,
        uint256 start,
        uint256 end
    ) public onlyOwner {
        ERC721 cosmopolityContract = ERC721(cosContractAdrress);
        address currOwner;
        for (uint256 currTokenId = start; currTokenId <= end; currTokenId++) {
            currOwner = cosmopolityContract.ownerOf(currTokenId);
            _mint(currOwner, currTokenId);
        }
    }

    function ownerMint(
        address to,
        uint256 rockId,
        address originContractAddress,
        string memory originTokenId
    ) public onlyOwner {
        _mintRock(to, originContractAddress, originTokenId, rockId);
    }

    function ownerAssignOrigin(
        address originContractAddress,
        string memory originTokenId,
        uint256 newRockId
    ) public onlyOwner {
        _assignOrigin(originContractAddress, originTokenId, newRockId);
    }

    /***** End of Owner Operations *****/
}
