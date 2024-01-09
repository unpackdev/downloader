// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./QueensAndKingsAvatars.sol";

contract FirstDrop is Ownable {
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    address public avatarContractAddress;
    address public signerAddress;
    address public sAddress;

    uint16 public sMintLimit = 300;
    uint16 public sMintedTokens = 0;

    uint16 public totalAvatars = 2000;
    uint256 public mintPrice = 0.423 ether;

    string public ipfsAvatars;

    mapping(uint16 => uint16) private tokenMatrix;
    mapping(address => uint8) public mintsPerUser;

    // DEBUG
    function setTotalAvatars(uint16 _totalAvatars) external onlyOwner {
        totalAvatars = _totalAvatars;
    }

    // ONLY OWNER

    /**
     * @dev Allows to withdraw the Ether in the contract
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Sets the mint price
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Sets the avatar contract address
     */
    function setAvatarContractAddress(address _address) external onlyOwner {
        avatarContractAddress = _address;
    }

    /**
     * @dev Sets the address that generates the signatures for whitelisting
     */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    /**
     * @dev Sets the address that can call mintTo
     */
    function setSAddress(address _sAddress) external onlyOwner {
        sAddress = _sAddress;
    }

    /**
     * @dev Sets how many mints can the sAddress do
     */
    function setSMintLimit(uint16 _sMintLimit) external onlyOwner {
        sMintLimit = _sMintLimit;
    }

    function setIPFSAvatars(string memory _ipfsAvatars) external onlyOwner {
        ipfsAvatars = _ipfsAvatars;
    }

    // END ONLY OWNER

    /**
     * @dev Mint function
     */
    function mint(
        uint8 _quantity,
        uint256 _fromTimestamp,
        uint256 _toTimestamp,
        uint8 _maxQuantity,
        bytes calldata _signature
    ) external payable callerIsUser {
        bytes32 messageHash = generateMessageHash(msg.sender, _fromTimestamp, _toTimestamp, _maxQuantity);
        address recoveredWallet = ECDSA.recover(messageHash, _signature);

        require(recoveredWallet == signerAddress, "Invalid signature for the caller");
        require(block.timestamp >= _fromTimestamp, "Too early to mint");
        require(block.timestamp <= _toTimestamp, "The signature has expired");

        QueensAndKingsAvatars qakContract = QueensAndKingsAvatars(avatarContractAddress);
        uint16 tmpTotalSupply = qakContract.totalSupply();

        uint256 tokensLeft = totalAvatars - tmpTotalSupply;
        require(tokensLeft > 0, "No tokens left to be minted");

        if (_quantity + mintsPerUser[msg.sender] > _maxQuantity) {
            _quantity = _maxQuantity - mintsPerUser[msg.sender];
        }

        if (_quantity > tokensLeft) {
            _quantity = uint8(tokensLeft);
        }

        uint256 totalMintPrice = mintPrice * _quantity;
        require(msg.value >= totalMintPrice, "Not enough Ether provided to mint");

        if (msg.value > totalMintPrice) {
            payable(msg.sender).transfer(msg.value - totalMintPrice);
        }

        require(_quantity != 0, "Address mint limit reached");

        mintsPerUser[msg.sender] += _quantity;

        for (uint16 i; i < _quantity; i++) {
            uint16 _tokenId = _getTokenToBeMinted(tmpTotalSupply);
            qakContract.mint(_tokenId, msg.sender);
            tmpTotalSupply++;
        }
    }

    /**
     * @dev mint to address
     */
    function mintTo(address[] memory _addresses) external {
        require(msg.sender == sAddress, "Caller is not allowed to mint");
        require(_addresses.length > 0, "At least one token should be minted");
        require(sMintedTokens + _addresses.length <= sMintLimit, "Mint limit reached");

        QueensAndKingsAvatars qakContract = QueensAndKingsAvatars(avatarContractAddress);
        uint16 tmpTotalSupply = qakContract.totalSupply();

        sMintedTokens += uint16(_addresses.length);
        for (uint256 i; i < _addresses.length; i++) {
            qakContract.mint(_getTokenToBeMinted(tmpTotalSupply), _addresses[i]);
            tmpTotalSupply++;
        }
    }

    /**
     * @dev mint to address
     */
    function mintToDev(address[] memory _addresses) external onlyOwner {
        require(_addresses.length > 0, "At least one token should be minted");

        QueensAndKingsAvatars qakContract = QueensAndKingsAvatars(avatarContractAddress);
        uint16 tmpTotalSupply = qakContract.totalSupply();

        uint256 tokensLeft = totalAvatars - tmpTotalSupply;
        require(tokensLeft > 0, "No tokens left to be minted");

        for (uint256 i; i < _addresses.length; i++) {
            qakContract.mint(_getTokenToBeMinted(tmpTotalSupply), _addresses[i]);
            tmpTotalSupply++;
        }
    }

    /**
     * @dev gets the amount of available tokens left to be minted
     */
    function getAvailableTokens() external view returns (uint16) {
        QueensAndKingsAvatars qakContract = QueensAndKingsAvatars(avatarContractAddress);

        return totalAvatars - qakContract.totalSupply();
    }

    /**
     * @dev Generates the message hash for the given parameters
     */
    function generateMessageHash(
        address _address,
        uint256 _fromTimestamp,
        uint256 _toTimestamp,
        uint8 _maxQuantity
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n85",
                    _address,
                    _fromTimestamp,
                    _toTimestamp,
                    _maxQuantity
                )
            );
    }

    /**
     * @dev Returns a random available token to be minted
     */
    function _getTokenToBeMinted(uint16 _totalMintedTokens) private returns (uint16) {
        uint16 maxIndex = totalAvatars + sMintLimit - _totalMintedTokens;
        uint16 random = _getRandomNumber(maxIndex, _totalMintedTokens);

        uint16 tokenId = tokenMatrix[random];
        if (tokenMatrix[random] == 0) {
            tokenId = random;
        }

        tokenMatrix[maxIndex - 1] == 0 ? tokenMatrix[random] = maxIndex - 1 : tokenMatrix[random] = tokenMatrix[
            maxIndex - 1
        ];

        // IDs start from 1 instead of 0
        return tokenId + 1;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint16 _upper, uint16 _totalMintedTokens) private view returns (uint16) {
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

        return (random % _upper);
    }
}
