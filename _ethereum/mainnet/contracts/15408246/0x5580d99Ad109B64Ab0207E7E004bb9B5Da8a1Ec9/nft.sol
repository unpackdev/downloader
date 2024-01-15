//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract GoblinBears is ERC721A, Ownable, ReentrancyGuard {
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 20;
    uint256[] public tiers = [1500, 5000, 10000];
    uint256[] public prices = [0, 0.003 ether, 0.007 ether];
    uint256[] public maxMints = [1, 7, 15];
    bool public paused = false;
    bytes32 public WLRoot;
    uint256 public WLMax = 3000;
    uint256 public WLPrice = 0.004 ether;

    struct CurrentData {
        uint256 currStage;
        uint256 currPrice;
        uint256 currMaxMint;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        bytes32 _WLRoot
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        WLRoot = _WLRoot;
    }

    function WLMint(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        payable
    {
        address _caller = msg.sender;
        require(maxSupply >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        uint256 callerBalance = balanceOf(_caller);
        require(
            _amount + callerBalance <= WLMax,
            "Exceeds Maximum Allowed Per Whitelist"
        );
        bytes32 leaf = keccak256(abi.encodePacked(_caller));

        require(
            MerkleProof.verify(_merkleProof, WLRoot, leaf),
            "This address is not a part of whitelist"
        );
        require(msg.value >= WLPrice * _amount, "Insufficient funds provided");
        _safeMint(_caller, _amount);
    }

    function mint(uint256 _amount) external payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        CurrentData memory currData = getCurrentData();
        uint256 currBalance = balanceOf(msg.sender);
        require(_amount > 0, "need to mint at least 1 NFT");

        require(supply + _amount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            if (currData.currStage == 0) {
                require(
                    _amount <= currData.currMaxMint,
                    "max mint amount per session exceeded"
                );
            } else {
                require(
                    _amount + currBalance <= currData.currMaxMint,
                    "max mint amount per Address exceeded"
                );
            }
            require(
                msg.value >= currData.currPrice * _amount,
                "insufficient funds"
            );
        }

        _safeMint(msg.sender, _amount);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        return super.isApprovedForAll(owner, operator);
    }

    function _extract(address receiver) internal {
        payable(receiver).transfer(address(this).balance);
    }

    function getCurrentStage() public view returns (uint256) {
        uint256 currSupply = totalSupply();
        for (uint256 i; i < tiers.length; i++) {
            uint256 currTier = tiers[i];
            if (currTier > currSupply) {
                return i;
            }
        }
        return 150000;
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 currStage = getCurrentStage();
        uint256 currPrice = prices[currStage];
        return currPrice;
    }

    function getCurrentMaxMint() public view returns (uint256) {
        uint256 currStage = getCurrentStage();
        uint256 currMaxMint = maxMints[currStage];
        return currMaxMint;
    }

    function getCurrentData() public view returns (CurrentData memory) {
        uint256 currStage = getCurrentStage();
        uint256 currPrice = prices[currStage];
        uint256 currMaxMint = maxMints[currStage];
        CurrentData memory currData = CurrentData(
            currStage,
            currPrice,
            currMaxMint
        );
        return currData;
    }

    function getTxCost(uint256 _amount) public view returns (uint256) {
        uint256 currStage = getCurrentStage();
        uint256 predictedCurrentTier = tiers[currStage];
        uint256 predictedCurrentPrice = prices[currStage];
        uint256 newSupply = totalSupply() + _amount;
        if (newSupply > predictedCurrentTier) {
            uint256 newStage = currStage + 1;
            uint256 newPrice = prices[newStage];
            uint256 totalAtCurrent = tiers[currStage] - totalSupply();
            uint256 totalAtNew = _amount - totalAtCurrent;
            uint256 priceForCurr = predictedCurrentPrice * totalAtCurrent;
            uint256 priceForNew = newPrice * totalAtNew;
            uint256 totalPrice = priceForCurr + priceForNew;
            return totalPrice;
        } else {
            uint256 totalPrice = predictedCurrentPrice * _amount;
            return totalPrice;
        }
    }

    // onlyOwner Functions

    function setTiers(uint256[] calldata newTiers) public onlyOwner {
        delete tiers;
        tiers = newTiers;
    }

    function airdrop(address receiver, uint256 _amount) public onlyOwner {
        _safeMint(receiver, _amount);
    }

    function airdropAll(address[] calldata receivers, uint256 _amount)
        public
        onlyOwner
    {
        for (uint256 i; i < receivers.length; i++) {
            address currReceiver = receivers[i];
            _safeMint(currReceiver, _amount);
        }
    }

    function setPrices(uint256[] calldata newPrices) public onlyOwner {
        delete prices;
        prices = newPrices;
    }

    function setMaxMints(uint256[] calldata _maxMints) public onlyOwner {
        delete maxMints;
        maxMints = _maxMints;
    }

    function withdraw() external onlyOwner nonReentrant {
        _extract(msg.sender);
    }

    function setWLRoot(bytes32 _newRoot) external onlyOwner {
        WLRoot = _newRoot;
    }

    function setWLMax(uint256 _newMax) external onlyOwner {
        WLMax = _newMax;
    }

    function setWLPrice(uint256 _newPrice) external onlyOwner {
        WLPrice = _newPrice;
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
