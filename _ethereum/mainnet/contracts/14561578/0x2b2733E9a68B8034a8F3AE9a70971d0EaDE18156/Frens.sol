//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @title:  Playground Frens
// @desc:   8,192 frens, ready to play.
// @url:    https://www.playgroundfrens.com/

import "./MerkleProof.sol";
import "./ERC721BaseTokenURI.sol";

contract Frens is ERC721BaseTokenURI {
    uint256 public constant MAX_PUBLIC_MINT = 10;
    uint256 public constant MAX_SUPPLY = 8192;
    uint256 public constant MAX_UNIQUE_COUNT = 125;
    uint256 public constant TOKEN_PRICE = 0.09 ether;

    enum State {
        Paused,
        RecessMint,
        PresaleMint,
        PublicMint,
        Ended
    }

    mapping(address => uint256) public presaleMintCount;
    mapping(address => bool) public hasMintedRecess;
    uint256 maxPresaleMint = 10;
    bytes32 public presaleMerkleRoot;
    bytes32 public recessMerkleRoot;
    State public state = State.Paused;
    uint256 public currentNormalTokenId = MAX_UNIQUE_COUNT;
    uint256 public currentUniqueTokenId = 0;

    constructor(string memory baseTokenURI) ERC721BaseTokenURI('Frens', 'FRENS', baseTokenURI) {}

    modifier isRightState(State _state) {
        require(state == _state, 'Wrong state for this action.');
        _;
    }

    modifier sentCorrectValue(uint256 numberOfTokens) {
        require(msg.value >= numberOfTokens * TOKEN_PRICE, 'Not enough ETH sent.');
        _;
    }

    modifier validMerkleProof(bytes32[] calldata merkleProof, bytes32 merkleRoot) {
        bytes32 leafNode = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(merkleProof, merkleRoot, leafNode), 'Invalid merkleProof.');
        _;
    }

    modifier validNumberOfTokens(uint256 numberOfTokens, uint256 maxTokens) {
        require(numberOfTokens > 0 && numberOfTokens <= maxTokens, 'Invalid number of tokens.');
        _;
    }

    // NB: Setting State.Ended *permanently* ends the sale, which has the effect of "burning" what's left of the 8,192 supply
    function setState(State _state) external onlyOwner {
        require(state != State.Ended, "The sale has ended and can't be restarted.");
        state = _state;
    }

    function publicMint(uint256 numberOfTokens)
        external
        payable
        isRightState(State.PublicMint)
        sentCorrectValue(numberOfTokens)
        validNumberOfTokens(numberOfTokens, MAX_PUBLIC_MINT)
    {
        require(currentNormalTokenId + numberOfTokens <= MAX_SUPPLY, 'Not enough tokens left.');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintFren(_msgSender(), false);
        }
    }

    function presaleMint(bytes32[] calldata merkleProof, uint256 numberOfTokens)
        external
        payable
        isRightState(State.PresaleMint)
        sentCorrectValue(numberOfTokens)
        validMerkleProof(merkleProof, presaleMerkleRoot)
        validNumberOfTokens(numberOfTokens, maxPresaleMint)
    {
        require(
            presaleMintCount[_msgSender()] + numberOfTokens <= maxPresaleMint,
            'Already claimed your presale Frens!'
        );
        presaleMintCount[_msgSender()] += numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintFren(_msgSender(), false);
        }
    }

    function recessMint(bytes32[] calldata merkleProof)
        external
        isRightState(State.RecessMint)
        validMerkleProof(merkleProof, recessMerkleRoot)
    {
        require(!hasMintedRecess[_msgSender()], 'Already claimed your free Fren!');
        hasMintedRecess[_msgSender()] = true;
        _mintFren(_msgSender(), false);
    }

    function uniqueMint(address recipient) external onlyOwner {
        require(currentUniqueTokenId < MAX_UNIQUE_COUNT, 'All the uniques have been minted.');
        _mintFren(recipient, true);
    }

    function _mintFren(address recipient, bool isUnique) private {
        if (isUnique) {
            currentUniqueTokenId++;
        } else {
            currentNormalTokenId++;
        }
        _mint(recipient, isUnique ? currentUniqueTokenId : currentNormalTokenId);
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}('');
        require(success, 'Withdraw failed.');
    }

    function setMaxPresaleMint(uint256 _maxPresaleMint) external onlyOwner {
        maxPresaleMint = _maxPresaleMint;
    }

    function setPresaleMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        presaleMerkleRoot = _merkleRoot;
    }

    function setRecessMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        recessMerkleRoot = _merkleRoot;
    }
}
