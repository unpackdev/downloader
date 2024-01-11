//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

// File contracts/test.sol

contract TigerToonz is ERC721A, Ownable, ReentrancyGuard {
    string private baseURI = "";
    string public constant baseExtension = ".json";
    string private notRevealedUri;
    uint256 public MAX_SUPPLY = 3333;
    bool public paused = false;
    bool public revealed = false;
    bytes32 public OGRoot =
        0x0beb1deb78d32659198b8dce13e3a2587b692487dd9ef5fb252af9a4128e0a3b;
    // 0xbbd077c886f07d0587c72b47a025a07b3ae3e902c4d7c81160885e0dc633d55f;
    bytes32 public WLRoot =
        0x664872b0feb3b945bd25e6c9063123e8c7891e585f9160ef6ead1186212468d0;
    //0x4baa8d583650af63b0c2d2193a4fa4b06e6445f07a62ea41478c6b1a37c11b9e;

    uint256[] public prices = [0.03 ether, 0.04 ether, 0.05 ether];
    uint256[] public maxMints = [5, 3];
    uint256 public presaleEndTime;
    uint256 public presaleStartTime;
    address public marketingWallet = 0xE2A48cCBA6678011bEDfaA365514352Ab8c63f51;
    address public gameDevAddress = 0x7B9a595f74c360111e8fed196F101b1Db7F64392;
    address public metaverseAddress = 0x6581DE24627fa0B0e3E8F8eDf238CfBA396d730a;
    address public charityAddress = 0x92AFfeeFC212C2d7CFe9d425deFfd77D9743EF58;
    uint256 public marketingPercent = 30;
    uint256 public gameDevPercent = 35;
    uint256 public metaPercent = 20;
    uint256 public charityPercent = 5;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        uint256 _duration,
        uint256 _presaleStartTime
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        presaleEndTime = _presaleStartTime + _duration;
        presaleStartTime = _presaleStartTime;
    }

    function presaleMint(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        payable
    {
        address _caller = msg.sender;
        require(!paused, "Paused");
        require(MAX_SUPPLY >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        require(tx.origin == _caller, "No contracts");
        bytes32 leaf = keccak256(abi.encodePacked(_caller));
        uint256 mintCost;
        uint256 maxMint;
        bool isWL;
        if (MerkleProof.verify(_merkleProof, OGRoot, leaf)) {
            mintCost = prices[0];
            isWL = true;
            maxMint = maxMints[0];
        } else {
            if (MerkleProof.verify(_merkleProof, WLRoot, leaf)) {
                mintCost = prices[1];
                isWL = true;
                maxMint = maxMints[1];
            } else {
                mintCost = prices[2];
                isWL = false;
                maxMint = maxMints[1];
            }
        }
        uint256 callerBalance = balanceOf(msg.sender);
        uint256 totalMintCost = mintCost * _amount;
        require(block.timestamp > presaleStartTime, "Sale Has Not Started Yet");
        require(block.timestamp < presaleEndTime, "Presale has Ended");
        if (_caller != owner()) {
            require(isWL == true, "user is not whitelisted");

            require(
                callerBalance + _amount <= maxMint,
                "exceeds maximum allowed during whitelist"
            );
            require(totalMintCost == msg.value, "Invalid funds provided");
        }

        _safeMint(_caller, _amount);
    }

    function mint(uint256 _amount) external payable {
        address _caller = msg.sender;
        require(!paused, "Paused");
        require(MAX_SUPPLY >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        require(tx.origin == _caller, "No contracts");
        uint256 mintCost = prices[2];
        uint256 totalMintCost = mintCost * _amount;
        require(block.timestamp > presaleEndTime, "Presale has not ended yet");
        if (_caller != owner()) {
            require(totalMintCost == msg.value, "Invalid funds provided");
        }

        _safeMint(_caller, _amount);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return super.isApprovedForAll(owner, operator);
    }

    function maxMintAmount(bytes32[] calldata _merkleProof)
        public
        view
        returns (uint256)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint256 maxMint;
        if (block.timestamp < presaleEndTime) {
            if (MerkleProof.verify(_merkleProof, OGRoot, leaf)) {
                maxMint = maxMints[0];
            } else {
                if (MerkleProof.verify(_merkleProof, WLRoot, leaf)) {
                    maxMint = maxMints[1];
                } else {
                    maxMint = maxMints[1];
                }
            }
        } else {
            maxMint = maxMints[0];
        }
        return maxMint;
    }

    function currentPrice(bytes32[] calldata _merkleProof)
        public
        view
        returns (uint256)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint256 mintCost;
        if (block.timestamp < presaleEndTime) {
            if (MerkleProof.verify(_merkleProof, OGRoot, leaf)) {
                mintCost = prices[0];
            } else {
                if (MerkleProof.verify(_merkleProof, WLRoot, leaf)) {
                    mintCost = prices[1];
                } else {
                    mintCost = prices[2];
                }
            }
        } else {
            mintCost = prices[2];
        }
        return mintCost;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function withdraw() external onlyOwner nonReentrant {
        _withdraw(msg.sender);
    }

    function changePrice(uint256 _newPrice, uint256 priceindex)
        public
        onlyOwner
    {
        prices[priceindex] = _newPrice;
    }

    function changeWithdrawPercentages(
        uint256 _newmkt,
        uint256 _newGameDev,
        uint256 _newMeta,
        uint256 _newCharity
    ) public onlyOwner {
        marketingPercent = _newmkt;
        gameDevPercent = _newGameDev;
        metaPercent = _newMeta;
        charityPercent = _newCharity;
    }

    function setMarketingAddress(address _newAddress) public onlyOwner {
        marketingWallet = _newAddress;
    }

    function setGameDevAddress(address _newAddress) public onlyOwner {
        gameDevAddress = _newAddress;
    }

    function setMetaverseAddress(address _newAddress) public onlyOwner {
        metaverseAddress = _newAddress;
    }

    function setCharityAddress(address _newAddress) public onlyOwner {
        charityAddress = _newAddress;
    }

    function setOGMaxMint(uint256 _newMax) public onlyOwner {
        maxMints[0] = _newMax;
    }

    function setWLMaxMint(uint256 _newMax) public onlyOwner {
        maxMints[1] = _newMax;
    }

    function _withdraw(address _caller) private {
        uint256 currBalance = address(this).balance;
        uint256 mktShare = (currBalance * marketingPercent) / 100;
        uint256 gameDevShare = (currBalance * gameDevPercent) / 100;
        uint256 metaShare = (currBalance * metaPercent) / 100;
        uint256 charityShare = (currBalance * charityPercent) / 100;

        payable(marketingWallet).transfer(mktShare);
        payable(gameDevAddress).transfer(gameDevShare);
        payable(metaverseAddress).transfer(metaShare);
        payable(charityAddress).transfer(charityShare);
        payable(_caller).transfer(address(this).balance);
    }

    function setupOS() external onlyOwner {
        _safeMint(_msgSender(), 1);
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function extendPSTime(uint256 _newStart, uint256 _duration)
        public
        onlyOwner
    {
        presaleStartTime = _newStart;
        presaleEndTime = _newStart + _duration;
    }

    function updateMaxSupply(uint256 _newSupply) external onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setOGRoot(bytes32 _newRoot) public onlyOwner {
        OGRoot = _newRoot;
    }

    function airdrop(address _to, uint256 _amount) public onlyOwner {
        _safeMint(_to, _amount);
    }

    function setWLRoot(bytes32 _newRoot) public onlyOwner {
        WLRoot = _newRoot;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }
}
