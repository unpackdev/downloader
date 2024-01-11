//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";

contract GuysERC721 is ERC721A, Ownable, Pausable {
    using ECDSA for bytes32;
    string public baseURI;

    uint128 private currentBatchNumber = 1;

    mapping(address => bool) private hasAlreadyMintedOtherBatches;
    mapping(address => bool) private hasMintedFromWhitelist;
    mapping(uint256 => uint256) private batchNumberToPrice;
    mapping(uint256 => uint256) private batchNumberToTokenSupply;

    bytes32 private _whitelistMerkleRoot;

    // solhint-disable-next-line
    receive() external payable {}

    constructor() ERC721A("Guys", "GUY") {
        batchNumberToPrice[1] = 0 ether;
        batchNumberToPrice[2] = 0.02 ether;
        batchNumberToPrice[3] = 0.03 ether;
        batchNumberToPrice[4] = 0.04 ether;

        batchNumberToTokenSupply[1] = 2292;
        batchNumberToTokenSupply[2] = batchNumberToTokenSupply[1] + 1146;
        batchNumberToTokenSupply[3] = batchNumberToTokenSupply[2] + 1146;
        batchNumberToTokenSupply[4] = batchNumberToTokenSupply[3] + 1146;
    }

    function withdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWhitelistMerkleRoot(bytes32 newMerkleRoot_) external onlyOwner {
        _whitelistMerkleRoot = newMerkleRoot_;
    }

    function unpause() external onlyOwner {
        super._unpause();
    }

    function pause() external onlyOwner {
        super._pause();
    }

    function setBatchNumber(uint128 _newBatchNumber) external onlyOwner {
        currentBatchNumber = _newBatchNumber;
    }

    function resetHasAlreadyMinted(address[] memory _who) external onlyOwner {
        uint256 length = _who.length;
        for (uint256 i = 0; i < length; i++) {
            hasAlreadyMintedOtherBatches[_who[i]] = false;
        }
    }

    function ownerMint(address _to, uint128 quantity) external onlyOwner {
        internalMint(_to, quantity);
    }

    function mintFirstBatch(
        address _to,
        uint256 _amount,
        bytes32[] memory _proof
    ) external payable whenNotPaused {
        require(currentBatchNumber == 1, "Wrong batch!");
        require(_amount == 1, "Illegal amount!");
        require(hasMintedFromWhitelist[_to] == false, "Minted from whitelist!");
        require(_whitelistMerkleRoot != "", "Merkle not set!");
        require(
            MerkleProof.verify(
                _proof,
                _whitelistMerkleRoot,
                keccak256(abi.encodePacked(_to, _amount))
            ),
            "Not whitelisted!"
        );

        hasMintedFromWhitelist[_to] = true;

        internalMint(_to, _amount);
    }

    function mintOtherBatches(address _to, uint256 _amount)
        external
        payable
        whenNotPaused
    {
        require(hasAlreadyMintedOtherBatches[_to] == false, "Already minted!");
        require(_amount > 0 && _amount < 4, "Illegal amount!");
        require(
            msg.value == _amount * batchNumberToPrice[currentBatchNumber],
            "Illegal fund amount!"
        );

        hasAlreadyMintedOtherBatches[_to] = true;

        internalMint(_to, _amount);
    }

    function internalMint(address _to, uint256 _amount) internal {
        require(totalSupply() < 5730, "All GUYS have been minted");

        super._mint(_to, _amount, "", false);

        if (totalSupply() >= batchNumberToTokenSupply[currentBatchNumber]) {
            super._pause();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
