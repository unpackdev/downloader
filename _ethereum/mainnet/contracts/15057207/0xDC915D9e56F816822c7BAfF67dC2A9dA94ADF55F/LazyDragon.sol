// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./StringsUpgradeable.sol";

// `7MMF'                                `7MM"""Yb.
//   MM                                    MM    `Yb.
//   MM         ,6"Yb.  M"""MMV `7M'   `MF'MM     `Mb `7Mb,od8 ,6"Yb.  .P"Ybmmm ,pW"Wq.`7MMpMMMb.  ,pP"Ybd
//   MM        8)   MM  '  AMV    VA   ,V  MM      MM   MM' "'8)   MM :MI  I8  6W'   `Wb MM    MM  8I   `"
//   MM      ,  ,pm9MM    AMV      VA ,V   MM     ,MP   MM     ,pm9MM  WmmmP"  8M     M8 MM    MM  `YMMMa.
//   MM     ,M 8M   MM   AMV  ,     VVV    MM    ,dP'   MM    8M   MM 8M       YA.   ,A9 MM    MM  L.   I8
// .JMMmmmmMMM `Moo9^Yo.AMMmmmM     ,V   .JMMmmmdP'   .JMML.  `Moo9^Yo.YMMMMMb  `Ybmd9'.JMML  JMML.M9mmmP'
//                                 ,V                                 6'     dP
//                              OOb"                                  Ybmmmd'
//
// Contract by @nft_ved

contract LazyDragon is ERC721AUpgradeable, OwnableUpgradeable {
    // Constructors
    uint256 public constant MAX_SUPPLY = 6000;

    uint256 public mintPrice;
    uint256 public wlPrice;
    uint256 public presalePrice;

    uint256 public presaleSupply;
    uint256 public whitelistSupply;

    bool public isPublicSaleActive;
    bool public isWhitelistSaleActive;
    bool public isPresaleActive;

    uint256 public maxPerAddress;
    uint256 public maxPerAddressTotal;

    string public baseURI;
    string public presaleURI;

    uint256 public totalSupplyPresale;
    uint256 public totalSupplyWhitelist;

    bytes32 public merkleRoot;
    bytes32 public merkleRootFree;

    mapping(address => uint256) private _presaleMinted;
    mapping(address => uint256) private _whitelistMinted;
    mapping(address => uint256) private _freeMinted;

   

    function initialize() public initializerERC721A initializer {
        mintPrice = 0.04 ether;
        wlPrice = 0.03 ether;
        presalePrice = 0.02 ether;

        presaleSupply = 200;
        whitelistSupply = 1100;

        isPublicSaleActive = false;
        isWhitelistSaleActive = false;
        isPresaleActive = false;

        maxPerAddress = 5;
        maxPerAddressTotal = 15; // 5 for presale, 5 for WL , 5 for public

        baseURI = "ipfs://QmPvhnP8WtngiU48fdXEXBoHzrQJTQcC1rh3dVbuTmQpfA/";
        presaleURI = "ipfs://QmPvhnP8WtngiU48fdXEXBoHzrQJTQcC1rh3dVbuTmQpfA/";

        __ERC721A_init("LazyDragon", "LZYDRGN");
        __Ownable_init();
    }

    // Public functions
    function mint(uint256 _amount)
        external
        payable
        mintCompliance(
            _amount,
            isPublicSaleActive,
            maxPerAddressTotal,
            totalSupply(),
            MAX_SUPPLY
        )
    {
        require(
            _numberMinted(msg.sender) + _amount <= maxPerAddressTotal,
            "Max mint limit"
        );

        uint256 price = mintPrice;
        checkValue(price * _amount);
        _safeMint(msg.sender, _amount);
    }

    function freeMint(bytes32[] calldata _merkeProof)
        external
        payable
        mintCompliance(
            1,
            isPublicSaleActive,
            maxPerAddressTotal+1,
            totalSupply(),
            MAX_SUPPLY
        )
        whitelistCompliance(_merkeProof, merkleRootFree, msg.sender)
    {
        require(
            _freeMinted[msg.sender] < 1,
            "Max mint limit"
        );

        _freeMinted[msg.sender] += 1;
        _safeMint(msg.sender, 1);
    }

    function whitelistMint(uint256 _amount, bytes32[] calldata _merkeProof)
        external
        payable
        mintCompliance(
            _amount,
            isWhitelistSaleActive,
            maxPerAddress,
            totalSupplyWhitelist,
            whitelistSupply
        )
        whitelistCompliance(_merkeProof, merkleRoot, msg.sender)
    {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Not enough mints left");
        require(
            _whitelistMinted[msg.sender] + _amount <= maxPerAddress,
            "Max wl mint limit"
        );

        uint256 price = wlPrice;
        checkValue(price * _amount);
        _whitelistMinted[msg.sender] += (_amount);
        totalSupplyWhitelist += _amount;
        _safeMint(msg.sender, _amount);
    }

    function presaleMint(uint256 _amount, bytes32[] calldata _merkeProof)
        external
        payable
        mintCompliance(
            _amount,
            isPresaleActive,
            maxPerAddress,
            totalSupplyPresale,
            presaleSupply
        )
        whitelistCompliance(_merkeProof, merkleRoot, msg.sender)
    {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Not enough mints left");
        require(
            _presaleMinted[msg.sender] + _amount <= maxPerAddress,
            "Max presale mint limit"
        );

        uint256 price = presalePrice;
        checkValue(price * _amount);
        _presaleMinted[msg.sender] += (_amount);
        totalSupplyPresale += _amount;
        _safeMint(msg.sender, _amount);
    }

    function isWhitelisted(address _address, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        return
            MerkleProofUpgradeable.verify(
                _merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(_address))
            );
    }

    function numberPresaleMinted(address _owner) public view returns (uint256) {
        return _presaleMinted[_owner];
    }

    function numberWhitelistMinted(address _owner)
        public
        view
        returns (uint256)
    {
        return _whitelistMinted[_owner];
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (_tokenId <= presaleSupply) {
            return
                string(
                    abi.encodePacked(
                        presaleURI,
                        StringsUpgradeable.toString(_tokenId),
                        ".json"
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        StringsUpgradeable.toString(_tokenId),
                        ".json"
                    )
                );
        }
    }

    // Private functions
    function checkValue(uint256 price) private {
        if (msg.value > price) {
            (bool succ, ) = payable(msg.sender).call{
                value: (msg.value - price)
            }("");
            require(succ, "Transfer failed");
        } else if (msg.value < price) {
            revert("Not enough ETH sent");
        }
    }

    // Internal functions
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function adminMintTo(uint256 _amount, address _user)
        external
        payable
        onlyOwner
    {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Not enough mints left");
        _safeMint(_user, _amount);
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPresaleURI(string calldata _presaleURI) external onlyOwner {
        presaleURI = _presaleURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool succ, ) = payable(msg.sender).call{value: balance}("");
        require(succ, "transfer failed");
    }

    function togglePublicSaleActive() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function toggleWhitelistSaleActive() external onlyOwner {
        isWhitelistSaleActive = !isWhitelistSaleActive;
    }

    function togglePresaleActive() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMerkleRootFree(bytes32 _merkleRootFree) external onlyOwner {
        merkleRootFree = _merkleRootFree;
    }

    function setPresaleSupply(uint256 _presaleSupply) external onlyOwner {
        presaleSupply = _presaleSupply;
    }

    function setWhitelistSupply(uint256 _whitelistSupply) external onlyOwner {
        whitelistSupply = _whitelistSupply;
    }

    // Modifiers
    modifier mintCompliance(
        uint256 _amount,
        bool active,
        uint256 maxTx,
        uint256 allSupply,
        uint256 maxSupply
    ) {
        require(tx.origin == msg.sender, "No contract minting");
        require(active, "Mint is not open");
        require(_amount <= maxTx, "Too many mints per tx");
        require(allSupply + _amount <= maxSupply, "Not enough mints left");
        _;
    }

    modifier whitelistCompliance(
        bytes32[] calldata _merkleProof,
        bytes32 _merkleRoot,
        address sender
    ) {
        require(
            MerkleProofUpgradeable.verify(
                _merkleProof,
                _merkleRoot,
                keccak256(abi.encodePacked(sender))
            ),
            "Not in whitelist"
        );
        _;
    }
}
