// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @title Ant Republic ERC721A

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract AntRepublicERC721A is ERC721A, ERC2981, Ownable, PaymentSplitter {
    using Strings for uint;

    enum Step {
        Before,
        CodeSale,
        WhitelistSale,
        PublicSale,
        SoldOut,
        Reveal
    }

    uint private constant MAX_SUPPLY = 6000;
    uint private constant MAX_MINTABLE_SUPPLY = 5625;
    uint private constant maxPerAddress = 3;
    uint public mintPrice = 10000000000000000; // 0.01 ETH

    mapping(address => uint) public amountNFTsperWallet;
    mapping(string => uint) public amountNFTsperCode;
    mapping(string => address) public codeLinkedToWallet;

    Step public sellingStep;
    bytes32 public merkleRootWl;
    bytes32 public merkleRootCode;
    string public baseURI;
    string public baseCollectionURI;
    uint private teamLength;

    constructor(
        address[] memory _team,
        uint[] memory _teamShares,
        bytes32 _merkleRootWl,
        bytes32 _merkleRootCode,
        string memory _baseURI,
        string memory _baseCollectionURI,
        address royaltyReceiver,
        uint96 royaltyAmount
    ) ERC721A("The Ant Republic", "ANT") PaymentSplitter(_team, _teamShares) {
        merkleRootWl = _merkleRootWl;
        merkleRootCode = _merkleRootCode;
        baseURI = _baseURI;
        baseCollectionURI = _baseCollectionURI;
        teamLength = _team.length;
        _setDefaultRoyalty(royaltyReceiver, royaltyAmount);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function giftMany(
        address[] calldata _to,
        uint256[] calldata _amounts
    ) external onlyOwner {
        require(
            _to.length == _amounts.length,
            "Arrays must be the same length"
        );
        uint256 sum;
        for (uint i = 0; i < _amounts.length; i++) {
            sum += _amounts[i];
        }
        require(totalSupply() + sum <= MAX_SUPPLY, "Reached max supply");
        for (uint i = 0; i < _to.length; i++) {
            _safeMint(_to[i], _amounts[i]);
        }
    }

    function gift(address[] calldata _to) external onlyOwner {
        require(totalSupply() + _to.length <= MAX_SUPPLY, "Reached max supply");
        for (uint i = 0; i < _to.length; i++) {
            _safeMint(_to[i], 1);
        }
    }

    function whitelistMint(
        address _account,
        uint _quantity,
        bytes32[] calldata _proof
    ) external payable callerIsUser {
        require(
            sellingStep == Step.WhitelistSale,
            "Whitelist sale is not activated"
        );
        require(isWhiteListed(_account, _proof), "Not whitelisted");
        require(
            amountNFTsperWallet[_account] + _quantity <= maxPerAddress,
            "You can only get 3 NFT"
        );
        require(
            totalSupply() + _quantity <= MAX_MINTABLE_SUPPLY,
            "Max supply exceeded"
        );

        if (amountNFTsperWallet[_account] == 0) {
            if (_quantity > 1) {
                require(
                    msg.value >= mintPrice * (_quantity - 1),
                    "Not enough funds for additional NFTs"
                );
                amountNFTsperWallet[_account] += _quantity;
                _safeMint(_account, _quantity);
            } else {
                amountNFTsperWallet[_account] += _quantity;
                _safeMint(_account, 1);
            }
        } else {
            require(msg.value >= mintPrice * _quantity, "Not enough funds");
            amountNFTsperWallet[_account] += _quantity;
            _safeMint(_account, _quantity);
        }
    }

    function codeMint(
        address _account,
        string memory _code,
        uint _quantity,
        bytes32[] calldata _proof
    ) external payable callerIsUser {
        require(
            sellingStep == Step.CodeSale,
            "Referral Code sale is not activated"
        );
        require(isCodeValid(_code, _proof), "Code not valid");
        require(
            amountNFTsperCode[_code] + _quantity <= maxPerAddress,
            "You can only get 3 NFT per code"
        );
        require(
            totalSupply() + _quantity <= MAX_MINTABLE_SUPPLY,
            "Max supply exceeded"
        );

        if (amountNFTsperCode[_code] == 0) {
            codeLinkedToWallet[_code] = _account;
            if (_quantity > 1) {
                require(
                    msg.value >= mintPrice * (_quantity - 1),
                    "Not enough funds for additional NFTs"
                );

                amountNFTsperCode[_code] += _quantity;

                _safeMint(_account, _quantity);
            } else {
                amountNFTsperCode[_code] += _quantity;
                _safeMint(_account, 1);
            }
        } else {
            require(msg.value >= mintPrice * _quantity, "Not enough funds");
            require(
                codeLinkedToWallet[_code] == _account,
                "Code already used by another wallet"
            );
            amountNFTsperCode[_code] += _quantity;
            _safeMint(_account, _quantity);
        }
    }

    function publicSaleMint(
        address _account,
        uint _quantity
    ) external payable callerIsUser {
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(
            amountNFTsperWallet[msg.sender] + _quantity <= maxPerAddress,
            "You can only get 3 NFT"
        );
        require(
            totalSupply() + _quantity <= MAX_MINTABLE_SUPPLY,
            "Max supply exceeded"
        );

        require(msg.value >= mintPrice * _quantity, "Not enough funds");

        amountNFTsperWallet[_account] += _quantity;
        _safeMint(_account, _quantity);
    }

    function tokenURI(
        uint _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function setDefaultRoyalty(
        address _receiver,
        uint96 _amount
    ) external onlyOwner {
        _setDefaultRoyalty(_receiver, _amount);
    }

    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setCollectionBaseUri(
        string memory _baseCollectionURI
    ) external onlyOwner {
        baseCollectionURI = _baseCollectionURI;
    }

    function setMintPrice(uint _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMerkleRootWl(bytes32 _merkleRoot) external onlyOwner {
        merkleRootWl = _merkleRoot;
    }

    function setMerkleRootCode(bytes32 _merkleRoot) external onlyOwner {
        merkleRootCode = _merkleRoot;
    }

    function isWhiteListed(
        address _account,
        bytes32[] calldata _proof
    ) internal view returns (bool) {
        return _verifyWl(leaf(_account), _proof);
    }

    function isCodeValid(
        string memory _code,
        bytes32[] calldata _proof
    ) internal view returns (bool) {
        bytes32 leafData = keccak256(abi.encodePacked(_code));
        return MerkleProof.verify(_proof, merkleRootCode, leafData);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verifyWl(
        bytes32 _leaf,
        bytes32[] memory _proof
    ) internal view returns (bool) {
        return MerkleProof.verify(_proof, merkleRootWl, _leaf);
    }

    function releaseAll() external onlyOwner {
        for (uint i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return baseCollectionURI;
    }

    receive() external payable override {
        revert("Only if you mint");
    }
}
