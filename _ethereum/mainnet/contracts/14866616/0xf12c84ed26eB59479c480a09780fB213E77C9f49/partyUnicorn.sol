pragma solidity >=0.6.0 <0.8.9;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

//import "./console.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC20.sol";
import "./Counters.sol";
import "./Ownable.sol";

//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

interface IRandom {
    function updateRandomIndex() external;

    function getSomeRandomNumber(uint256 _seed, uint256 _limit)
        external
        view
        returns (uint16);
}

interface ISign {
    function updateRandomIndex() external;

    function verifyTokenForAddress(
        string calldata _salt,
        bytes calldata _token,
        address _address
    ) external view returns (bool);
}

contract PartyUnicorn is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint16 public version = 24;
    uint256 public MAX_TOKENS = 3333;
    uint256 public constant MINT_PER_TX_LIMIT = 10;

    uint256 public tokensMinted = 0;
    uint16 public phase = 0;
    bool private _paused = true;
    bool public revealed = false;
    string public notRevealedUri = "ipfs://QmRkuJFgDx8KUpTWzKcg4uCrwdbY4rYLox3TSZ6BaEJ5kU";

    mapping(uint16 => uint256) public phasePrice;

    IRandom public random;
    ISign public sign;

    string private _apiURI = "ipfs://QmZoBE1sGN6LRepgyH5cyW9aWqYfCC6oVh7Qt4sNyDcj8g/";

    // mapping(address => uint) private _whiteList;
    mapping(address => uint256) private _freeList;

    mapping(uint16 => bool) private _isQueen;

    uint16[] private _availableTokens;

    constructor() ERC721("PartyUnicorn", "PartyUnicorn") {
        // Phase 1 is available in the beginning
        switchToSalePhase(0, true);
        //switchToSalePhase(1, true);

        //Set default price for each phase
        phasePrice[0] = 0.085 ether;
        phasePrice[1] = 0.125 ether;
        phasePrice[2] = 0.15 ether;
        phasePrice[3] = 0.175 ether;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function getAvaTokenIds() public view returns (uint16[] memory) {
        uint16[] memory b = new uint16[](_availableTokens.length);
        for (uint256 i = 0; i < _availableTokens.length; i++) {
            b[i] = _availableTokens[i];
        }
        return b;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function setPaused(bool _state) external {
        _paused = _state;
    }

    function addAvailableTokens(uint16 _from, uint16 _to) public onlyOwner {
        internalAddTokens(_from, _to);
    }

    function internalAddTokens(uint16 _from, uint16 _to) internal {
        for (uint16 i = _from; i <= _to; i++) {
            _availableTokens.push(i);
        }
    }

    function switchToSalePhase(uint16 _phase, bool _setTokens)
        public
        onlyOwner
    {
        phase = _phase;

        if (!_setTokens) {
            return;
        }

        if (phase == 0) {
            internalAddTokens(1, 333);
        } else if (phase == 1) {
            internalAddTokens(334, 1333);
        } else if (phase == 2) {
            internalAddTokens(1334, 2333);
        } else if (phase == 3) {
            internalAddTokens(2334, 3333);
        }
    }

    function giveAway(uint256 _amount, address _address) public onlyOwner {
        require(tokensMinted + _amount <= MAX_TOKENS, "All tokens minted");
        require(
            _availableTokens.length > 0,
            "All tokens for this Phase are already sold"
        );

        tokensMinted += _amount;
        for (uint256 i = 0; i < _amount; i++) {
            uint16 tokenId = getTokenToBeMinted();
            _safeMint(_address, tokenId);
        }
    }

    // function addFreeList(uint _amount, address _address) public onlyOwner {
    //     _freeList[_address]= _amount;
    // }

    // function getUserFreeListAmount(address add) public view returns(uint){
    //     uint count = _freeList[add];
    //     return count;
    // }

    // modifier chekAndUpateFL(uint _mint_amount){

    //     require(_freeList[msg.sender]>0, "no free mint quota.");
    //     require(_freeList[msg.sender]>=_mint_amount, "Exceed free mint");

    //     _freeList[msg.sender]=_freeList[msg.sender]-_mint_amount;

    //     _;
    // }

    // function freeMint(uint _amount) public payable whenNotPaused chekAndUpateFL(_amount){
    //     require(msg.value == 0, "free!");
    //     specialMint(_amount);
    // }

    // function whiteListMint(string calldata _salt, bytes calldata _token, uint256 _amount)
    //     public
    //     payable
    //     whenNotPaused
    // {
    //     require(
    //         sign.verifyTokenForAddress(_salt, _token, msg.sender),
    //         "Not in whitelist"
    //     );
    //     require(tx.origin == msg.sender, "Only EOA");
    //     require(tokensMinted + _amount <= MAX_TOKENS, "All tokens minted");
    //     require(
    //         _availableTokens.length > 0,
    //         "All tokens for this Phase are already sold"
    //     );
    //     require(
    //         _amount > 0 && _amount <= MINT_PER_TX_LIMIT,
    //         "Invalid mint amount"
    //     );
    //     require(mintPrice(_amount) == msg.value, "Invalid payment amount");

    //     tokensMinted += _amount;

    //     for (uint256 i = 0; i < _amount; i++) {
    //         uint16 tokenId = getTokenToBeMinted();
    //         _safeMint(msg.sender, tokenId);

    //     }
    // }



    function mint(uint256 _amount) public payable whenNotPaused {
        require(tx.origin == msg.sender, "Only EOA");
        //require(phase > 0, "Whitelist Only!");
        require(tokensMinted + _amount <= MAX_TOKENS, "All tokens minted");
        require(
            _amount > 0 && _amount <= MINT_PER_TX_LIMIT,
            "Invalid mint amount"
        );
        require(
            _availableTokens.length > 0,
            "All tokens for this Phase are already sold"
        );

        require(mintPrice(_amount) == msg.value, "Invalid payment amount");

        tokensMinted += _amount;

        for (uint256 i = 0; i < _amount; i++) {
            uint16 tokenId = getTokenToBeMinted();
            _safeMint(msg.sender, tokenId);
        }
    }

    function mintPrice(uint256 _amount) public view returns (uint256) {
        return _amount * phasePrice[phase];
    }

    function getTokenToBeMinted() private returns (uint16) {
        uint256 rand = random.getSomeRandomNumber(
            _availableTokens.length,
            _availableTokens.length
        );

        uint16 tokenId = _availableTokens[rand];

        _availableTokens[rand] = _availableTokens[_availableTokens.length - 1];
        _availableTokens.pop();

        return tokenId;
    }

    function setRandom(address _random) external onlyOwner {
        random = IRandom(_random);
    }

    function setSign(address _sign) external onlyOwner {
        sign = ISign(_sign);
    }

    function changePhasePrice(uint16 _phase, uint256 _weiPrice)
        external
        onlyOwner
    {
        phasePrice[_phase] = _weiPrice;
    }

    function totalSupply() public view override returns (uint256) {
        return tokensMinted;
    }

    function _baseURI() internal view override returns (string memory) {
        return _apiURI;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _apiURI = uri;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
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
        
        if(revealed == false) {
            return notRevealedUri;
        }

        return bytes(_apiURI).length > 0
            ? string(abi.encodePacked(_apiURI, tokenId.toString()))
            : "";
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    function withdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}
