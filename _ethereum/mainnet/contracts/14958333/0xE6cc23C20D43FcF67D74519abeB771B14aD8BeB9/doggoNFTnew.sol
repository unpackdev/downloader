//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract DoggoNFT is ERC721A, Ownable, ReentrancyGuard {
    string private baseURI = "";
    string public constant baseExtension = ".json";
    string private notRevealedUri;
    uint256 public MAX_SUPPLY = 10000;
    bool public paused = false;
    bool public revealed = false;
    uint256 public price = 0.1 ether;
    uint256 public presalePrice = 0.08 ether;
    bytes32 public ROOT;
    uint256 public PRESALE_MAX_PER_WALLET = 3;
    uint256 public MAX_PER_TX = 10;
    uint256 public presaleEndTime;
    uint256 public presaleStartTime;

    

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        bytes32 _initRoot,
        uint256 _presaleStartTime,
        uint256 _duration
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleStartTime + _duration;
        ROOT = _initRoot;
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
        bool isWL = isWhitelisted(_caller, _merkleProof);
        uint256 callerBalance = balanceOf(msg.sender);
        uint256 userMaxMint = maxMintAmount();
        uint256 totalMintCost = presalePrice * _amount;
        require(block.timestamp > presaleStartTime, "Sale Has Not Started Yet");
        require(block.timestamp < presaleEndTime, "Presale has Ended");
        if (_caller != owner()) {
            require(isWL == true, "user is not whitelisted");
            require(
                callerBalance + _amount <= userMaxMint,
                "Exceeds Maximum Allowed During Whitelist"
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
        uint256 mintCost = price;
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

    function isWhitelisted(address _user, bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        if (MerkleProof.verify(_merkleProof, ROOT, leaf)) {
            return true;
        } else {
            return false;
        }
    }

    function maxMintAmount() public view returns (uint256) {
        uint256 maxMint;
        if (block.timestamp < presaleEndTime) {
            maxMint = PRESALE_MAX_PER_WALLET;
        } else {
            maxMint = MAX_PER_TX;
        }
        return maxMint;
    }

    function currentPrice() public view returns (uint256) {
        if (block.timestamp < presaleEndTime) {
            return presalePrice;
        } else {
           return price;
        }
        
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function withdraw() external onlyOwner nonReentrant {
        _withdraw(msg.sender);
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function _withdraw(address _caller) private {
        payable(_caller).transfer(address(this).balance);
    }

    function setmaxMintAmounts(uint256 presaleMax, uint256 _newMax)
        public
        onlyOwner
    {
        PRESALE_MAX_PER_WALLET = presaleMax;
        MAX_PER_TX = _newMax;
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

    function updateMaxSupply(uint256 _newSupply) external onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function airdrop(address _to, uint256 _amount) public onlyOwner {
        require(!paused, "Paused");
        require(MAX_SUPPLY >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        require(tx.origin == msg.sender, "No contracts");
        _safeMint(_to, _amount);
    }

    function airDropAll(address[] calldata _addressList, uint256 amount)
        public
        onlyOwner
    {
        require(!paused, "Paused");
        require(MAX_SUPPLY >= totalSupply() + amount, "Exceeds max supply");
        require(amount > 0, "No 0 mints");
        require(tx.origin == msg.sender, "No contracts");
        for (uint256 i = 0; i < _addressList.length; i++) {
            address currRecipient = _addressList[i];
            _safeMint(currRecipient, amount);
        }
    }

    function updateRoot(bytes32 _newRoot) public onlyOwner {
        ROOT = _newRoot;
    }

    function extendSaleTimes(uint256 _newStart, uint256 _duration)
        public
        onlyOwner
    {
        presaleStartTime = _newStart;
        presaleEndTime = _newStart + _duration;
    }

    function changePresalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
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