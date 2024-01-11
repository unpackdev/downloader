// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./RaregotchiToyInterface.sol";

contract RaregotchiToyMinting is Ownable {
    RaregotchiToyInterface toyContract;

    uint16 public totalTokens = 3000;
    uint16 public totalSupply = 0;

    uint256 public mintPrice = 0.25 ether;

    bool private isFrozen = false;

    address public signerAddress;

    mapping(uint8 => mapping(address => uint8)) public mintedPerWalletByStage;
    mapping(uint16 => uint16) private tokenMatrix;

    modifier callerIsUser() {
        // solium-disable-next-line security/no-tx-origin
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * @dev Allows to withdraw the Ether in the contract
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Set the pet contract address
     */
    function setToyContractAddress(address _address) external onlyOwner {
        toyContract = RaregotchiToyInterface(_address);
    }

    /**
     * @dev Set the total amount of tokens
     */
    function setTotalTokens(uint16 _totalTokens) external onlyOwner {
        totalTokens = _totalTokens;
    }

    /**
     * @dev Set the mint price
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Sets the address that generates the signatures for whitelisting
     */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    function devMint(address _to, uint16[] calldata _tokenIds)
        external
        onlyOwner
    {
        uint256[] memory tokenIds = new uint256[](_tokenIds.length);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            useTokenId(_tokenIds[i]);
            tokenIds[i] = _tokenIds[i];
        }

        totalSupply += uint16(tokenIds.length);
        toyContract.batchMint(_to, tokenIds);
    }

    function marketingMint(uint16 amount) external onlyOwner {
        require(totalSupply < totalTokens, "Not tokens left to be minted");

        uint16 _amount = amount;

        if (totalSupply + _amount > totalTokens) {
            _amount = totalTokens - totalSupply;
        }

        uint256[] memory tokenIds = new uint256[](_amount);

        uint16 tmpTotalMintedTokens = totalSupply;
        totalSupply += _amount;

        for (uint256 i; i < _amount; i++) {
            tokenIds[i] = _getTokenToBeMinted(tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }

        toyContract.batchMint(msg.sender, tokenIds);
    }

    function mint(
        uint8 amount,
        uint8 stage,
        uint8 maxAmount,
        uint256 fromTimestamp,
        bytes calldata signature
    ) external payable callerIsUser {
        bytes32 messageHash = generateMintHash(
            amount,
            stage,
            maxAmount,
            msg.sender,
            fromTimestamp
        );
        address recoveredWallet = ECDSA.recover(messageHash, signature);
        require(
            recoveredWallet == signerAddress,
            "Invalid signature for the caller"
        );
        require(block.timestamp >= fromTimestamp, "Too early to mint");
        require(totalSupply < totalTokens, "Not tokens left to be minted");
        require(amount > 0, "At least one token should be minted");

        uint8 _amount = amount;

        if (totalSupply + _amount > totalTokens) {
            _amount = uint8(totalTokens - totalSupply);
        }

        require(
            mintedPerWalletByStage[stage][msg.sender] + _amount <= maxAmount,
            "Caller cannot mint more tokens"
        );

        uint256 totalMintPrice = mintPrice * _amount;

        require(
            msg.value >= totalMintPrice,
            "Not enough Ether to mint the tokens"
        );

        if (msg.value > totalMintPrice) {
            payable(msg.sender).transfer(msg.value - totalMintPrice);
        }

        uint256[] memory tokenIds = new uint256[](_amount);

        uint16 tmpTotalMintedTokens = totalSupply;
        mintedPerWalletByStage[stage][msg.sender] += _amount;
        totalSupply += _amount;

        for (uint256 i; i < _amount; i++) {
            tokenIds[i] = _getTokenToBeMinted(tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }

        toyContract.batchMint(msg.sender, tokenIds);
    }

    function getAvailableTokens() public view returns (uint16) {
        return totalTokens - totalSupply;
    }

    // Private and Internal functions

    function generateMintHash(
        uint8 amount,
        uint8 stage,
        uint8 maxAmount,
        address _address,
        uint256 _fromTimestamp
    ) internal pure returns (bytes32) {
        bytes32 _hash = keccak256(
            abi.encodePacked(
                _address, // 20 bytes
                _fromTimestamp, // 32 bytes(uint256)
                amount, // 1 byte (uint8)
                stage, // 1 byte (uint8)
                maxAmount // 1 bytes (uint16)
            )
        );

        bytes memory result = abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            _hash
        );

        return keccak256(result);
    }

    /**
     * @dev Returns a random available token to be minted
     *
     * Code used as reference:
     * https://github.com/1001-digital/erc721-extensions/blob/main/contracts/RandomlyAssigned.sol
     */
    function _getTokenToBeMinted(uint16 _totalMintedTokens)
        private
        returns (uint16)
    {
        uint16 maxIndex = totalTokens - _totalMintedTokens;
        uint16 random = _getRandomNumber(maxIndex, _totalMintedTokens);

        uint16 tokenId = tokenMatrix[random];

        if (tokenMatrix[random] == 0) {
            tokenId = random;
        }

        tokenMatrix[maxIndex - 1] == 0
            ? tokenMatrix[random] = maxIndex - 1
            : tokenMatrix[random] = tokenMatrix[maxIndex - 1];

        return tokenId + 1;
    }

    function useTokenId(uint16 _id) private {
        uint16 maxIndex = totalTokens - totalSupply;
        uint16 nonRandom = _id - 1;

        uint16 tokenId = tokenMatrix[nonRandom];

        if (tokenMatrix[nonRandom] == 0) {
            tokenId = nonRandom;
        }

        tokenMatrix[maxIndex - 1] == 0
            ? tokenMatrix[nonRandom] = maxIndex - 1
            : tokenMatrix[nonRandom] = tokenMatrix[maxIndex - 1];
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint16 _upper, uint16 _totalMintedTokens)
        private
        view
        returns (uint16)
    {
        uint16 random = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _totalMintedTokens,
                        blockhash(block.number - 1),
                        block.coinbase,
                        block.difficulty,
                        msg.sender
                    )
                )
            )
        );

        return random % _upper;
    }
}
