// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;



import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";


contract MorpheusTerminal is ERC1155, Ownable {

    // there is always a day after night
    
    using Strings for uint256;

    bytes32 private phrase_;
    string public name;
    string public symbol;
    bool public paused;
    uint256 public currentSuccessfulTokenId = 1;
    uint256 step = 0;
    uint256 bufferForNextIteration = 6;
    mapping(uint256 => uint256) public isSuccessfullToken;
    uint256 priceToMint = 0.02 ether;
    mapping(address => mapping(uint256 => bool))
        public mintedOnCurrentIteration;
    string baseUri;
    bool public isFinished;

    event PriceChanged(uint256 oldPrice, uint256 newPrice);

    event PauseStatusChanged(bool status);

    event PhaseStarted(uint256 indexed phase);

    modifier onlyUnpaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier isNotFinished() {
        require(!isFinished, "Mint is over");
        _;
    }

    // and there is always a night after day 

    constructor(
        string memory _uri,
        bytes32 _phrase,
        string memory _name,
        string memory _symbol
    ) ERC1155(_uri) {
        phrase_ = _phrase;
        name = _name;
        symbol = _symbol;
        baseUri = _uri;
        isSuccessfullToken[currentSuccessfulTokenId] = 1;
    }

    // and in dark night sky 

    function mint(string memory phrase) public payable onlyUnpaused isNotFinished returns(bool) {
        if (
            mintedOnCurrentIteration[msg.sender][currentSuccessfulTokenId] ==
            true
        ) {
            require(msg.value >= priceToMint, "Not enough message value");
        } else {
            mintedOnCurrentIteration[msg.sender][
                currentSuccessfulTokenId
            ] = true;
        }
        if (phrase_ == keccak256(bytes(phrase))) {
            _mint(msg.sender, currentSuccessfulTokenId, 1, "");
            paused = true;
            return true;
        } else {
            uint256 pseudoRandomSeed = uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        msg.sender
                    )
                )
            );
            _mint(msg.sender, (pseudoRandomSeed % 5) + 2 + step, 1, "");
            return false;
        }
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseUri, tokenId.toString(), ".json"));
    }

    function changeUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    // there is a lonely asteroid drifting away

    function nextStage(bytes32 newPhrase) public onlyOwner {
        phrase_ = newPhrase;
        paused = false;
        step += bufferForNextIteration;
        currentSuccessfulTokenId += bufferForNextIteration;
        isSuccessfullToken[currentSuccessfulTokenId] = 1;
        emit PhaseStarted(currentSuccessfulTokenId);
    }

    function changePrice(uint256 newPrice) public onlyOwner {
        uint256 oldPrice = priceToMint;
        priceToMint = newPrice;
        emit PriceChanged(oldPrice, newPrice);
    }

    function changePause() public onlyOwner {
        paused = !paused;
        emit PauseStatusChanged(paused);
    }

    function finalizeMint() public onlyOwner {
        isFinished = true;
    }

   function withdraw(address to, uint256 amount) public onlyOwner {
       (bool success, ) = to.call{value: amount}("");
        require(success);
   }
}
