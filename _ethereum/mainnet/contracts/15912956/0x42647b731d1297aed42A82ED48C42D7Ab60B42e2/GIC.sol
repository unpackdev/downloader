// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "./ERC1155Supply.sol";
import "./Ownable.sol";

contract GIC is ERC1155Supply, Ownable {
    uint256 public constant DEFAULT = 0;
    uint256 public constant GOLD = 1;
    uint256 public MAX_SUPPLY;
    uint256 private _totalMinted;

    string name_;
    string symbol_;

    // Used for random index assignment
    mapping(uint256 => uint256) private tokenMatrix;

    error MintLimit();
    error FreeMintLimit();

    constructor(uint256 maxSupply_)
        ERC1155("https://gateway.pinata.cloud/ipfs/QmdJYVPaGM9YPPoD8fV2gYGA5sdUx6WWoQGMDRXxknq3f3/{id}.json")
    {
        name_ = "GIC is Here";
        symbol_ = "GIC0";
        MAX_SUPPLY = maxSupply_;
    }

    function freeMint() public {
        if (msg.sender != tx.origin) revert FreeMintLimit();
        if (balanceOf(msg.sender, DEFAULT) != 0) revert FreeMintLimit();
        if (_totalMinted >= MAX_SUPPLY) revert MintLimit();
        if (_nextToken() == 0) {
            _mint(msg.sender, GOLD, 1, "");
        } else {
            _mint(msg.sender, DEFAULT, 1, "");
        }

        _totalMinted++;
    }

    function _enoughRandom() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        // solhint-disable-next-line
                        block.timestamp,
                        block.coinbase,
                        block.difficulty,
                        block.gaslimit
                    )
                )
            );
    }

    /// Get the next token ID
    /// @dev Randomly gets a new token ID and keeps track of the ones that are still available.
    /// @return the next token ID
    function _nextToken() internal returns (uint256) {
        uint256 maxIndex = MAX_SUPPLY - _totalMinted;
        uint256 random = _enoughRandom() % maxIndex;

        uint256 value = 0;
        if (tokenMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[random];
        }

        // If the last available tokenID is still unused...
        if (tokenMatrix[maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[random] = maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }

        return value;
    }

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }
}
