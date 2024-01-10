// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

// ███████╗████████╗██╗░░██╗██╗░░░░░██╗░░░░░░█████╗░███╗░░░███╗░█████╗░░██████╗
// ██╔════╝╚══██╔══╝██║░░██║██║░░░░░██║░░░░░██╔══██╗████╗░████║██╔══██╗██╔════╝
// █████╗░░░░░██║░░░███████║██║░░░░░██║░░░░░███████║██╔████╔██║███████║╚█████╗░
// ██╔══╝░░░░░██║░░░██╔══██║██║░░░░░██║░░░░░██╔══██║██║╚██╔╝██║██╔══██║░╚═══██╗
// ███████╗░░░██║░░░██║░░██║███████╗███████╗██║░░██║██║░╚═╝░██║██║░░██║██████╔╝
// ╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═════╝░

contract EthLlamasNFT is ERC721, Pausable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // ----- Cost and Supply config -----
    uint256 public constant maxSupply = 10000;
    uint256 private _cost = 0.02 ether;
    uint256 private _maxMintAmount = 20;
    uint256[] public ethLlamas;

    // current count of token supply
    Counters.Counter private _tokenSupply;

    // totalReserved EthLlamas will be used for giveaways and promotions
    uint256 private _totalReserved = 150;

    // The full ipfs path to project json files, expected format is "ipfs://<cin>/"
    string private _baseURIExtended = '';

    // Mapping which token we already handed out
    uint256[maxSupply] private indices;

    address private constant _ownerWallet = 0x918ce4d28caBDd597A147d82fc719398687074d2;

    // Events for functions that change internal settings
    event costSet(uint _amount);
    event maxMintAmountSet(uint _amount);

    constructor() ERC721("EthLlamasNFT", "ELNFT") {
        // Start with minting paused
        _pause();
    }

    function safeMint(uint256 _mintAmount) external virtual whenNotPaused payable nonReentrant {
        require(_mintAmount > 0, "Value for mintAmount needs to be greater than 0.");
        require(_mintAmount <= _maxMintAmount, "Value for mintAmount needs to be less than or equal to maxMintAmount.");
        require(_tokenSupply.current() + _mintAmount <= maxSupply - _totalReserved, "Current tokenSupply and mintAmount needs to be less than or equal to maxSupply.");
        require(msg.value >= _cost * _mintAmount, "Not enough ETH sent, check price.");
        _internalMint(msg.sender, _mintAmount);
    }

    function _internalMint(address _to, uint256 _mintAmount) internal {
        require(keccak256(abi.encodePacked((_baseURIExtended))) != keccak256(abi.encodePacked((""))), "No _baseURIExtended set.");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 mintIndex = randomIndex();
            _tokenSupply.increment();
            ethLlamas.push(mintIndex);
            _safeMint(_to, mintIndex);
        }
    }

    // ----- ERC-721 functions -----

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _baseURIExtended;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenSupply.current();
    }

    // ----- Overrides required by Solidity -----

    function _burn(uint256 tokenID) internal override(ERC721) {
        super._burn(tokenID);
        _tokenSupply.decrement();
    }

    function tokenURI(uint256 _tokenID) public view override(ERC721) returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(_tokenID), '.json'));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenID) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenID);
    }

    // ----- Getter functions -----

    function getCost() external view returns (uint256) {
        return _cost;
    }

    function getMaxMintAmount() external view returns (uint256) {
        return _maxMintAmount;
    }

    function getEthLlamas() external view returns (uint256 [] memory) {
        return ethLlamas;
    }

    function getReservedLeft() public view returns (uint256) {
        return _totalReserved;
    }

    // ----- Owner only functions -----

    // expects amount in wei, Ex: 60000000000000000 for 0.06 ETH
    function setCost(uint256 _newCost) external onlyOwner {
        _cost = _newCost;
        emit costSet(_newCost);
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
        _maxMintAmount = _newMaxMintAmount;
        emit maxMintAmountSet(_newMaxMintAmount);
    }

    // setBaseURI expects parameter format "ipfs://<CIN>/"
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _baseURIExtended = _newBaseURI;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    
    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(_ownerWallet).send(_balance));
    }

    function claimReserved(address _receiver, uint256 _amount) external onlyOwner {
        require(_amount <= _totalReserved, "Value for claim amount needs to be less than or equal to remaining total reserved.");
        _internalMint(_receiver, _amount);
        _totalReserved -= _amount;
    }

    // ----- Minting functions -----

    /// @notice Select a random number without modulo bias using a random seed and upper bound
    /// @param _entropy The seed for randomness
    /// @param _upperBound The upper bound of the desired number
    /// @return A random number less than the _upperBound
    function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
        require(_upperBound > 0, "UpperBound needs to be >0.");
        uint256 negation = _upperBound & (~_upperBound + 1);
        uint256 min = negation % _upperBound;
        uint256 randomNr = _entropy;
        while (true) {
            if (randomNr >= min) {
                break;
            }
            randomNr = uint256(keccak256(abi.encodePacked(randomNr)));
        }
        return randomNr % _upperBound;
    }

    /// @notice Generates a pseudo random number based on arguments with decent entropy
    /// @param max The maximum value we want to receive
    /// @return _randomNumber A random number less than the max
    function random(uint256 max) internal view returns (uint256 _randomNumber) {
        uint256 randomness = uint256(
            keccak256(
                abi.encode(
                    msg.sender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    blockhash(block.number - 1),
                    block.difficulty
                )
            )
        );
        _randomNumber = uniform(randomness, max);
        return _randomNumber;
    }

    /// @notice Generates a pseudo random index of our tokens that has not been used so far
    /// @return A random index between 0 and 9999
    function randomIndex() internal returns (uint256) {
        // id of the gerneated token
        uint256 tokenID = 0;
        //  number of tokens left to create
        uint256 totalSize = maxSupply - _tokenSupply.current();
        // generate a random index
        uint256 index = random(totalSize);
        // if we haven't handed out a token with nr index we that now

        uint256 tokenAtPlace = indices[index];

        // if we havent stored a replacement token...
        if (tokenAtPlace == 0) {
            //... we just return the current index
            tokenID = index;
        } else {
            // else we take the replace we stored with logic below
            tokenID = tokenAtPlace;
        }

        // get the highest token id we havent handed out
        uint256 lastTokenAvailable = indices[totalSize - 1];
        // we need to store a replacement token for the next time we roll the same index
        // if the last token is still unused...
        if (lastTokenAvailable == 0) {
            // ... we store the last token as index
            indices[index] = totalSize - 1;
        } else {
            // ... we store the token that was stored for the last token
            indices[index] = lastTokenAvailable;
        }

        return tokenID;
    }
}