// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./IERC721A.sol";

error ZeroAddress();
error NoWithdrawAddress();
error ZeroBalance();
error SaleNotActive();
error ClaimNotActive();
error InvalidPayment();
error InvalidSignature();
error InvalidInput();
error ContractCaller();
error MaxSupplyReached();
error InvalidSignatureLength();
error AllocationExceeded();

contract ApolloPassNFT is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    string private _contractURI = "ipfs://QmXUmco8L6RdmWNaAxPxEiMa93ffjYHTtuKge3WgVCTeY1";

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint256 public supply = 10000;
    uint256 public price = 0.099 ether;
    bool public isSaleActive = false;
    bool public isClaimActive = false;
    uint256 public exchangeRate = 6;
    address public signerAddress = 0x3623eD2CFC9F7237ebB6B7a36edB49328dAb9f3C;
    address public withdrawAddress = 0x6750B435a98A6595110351fe324dE9E9F7a673a8;
    string public baseURI = "ipfs://QmZJpWd3oMs4vszG59rAwqWLsWprurXA5wg6Z3NrVgRe6n/";
    address public apesTogetherAddress;

    constructor(address _apesTogetherAddress) ERC721A("Apollo Pass", "AP") {
        apesTogetherAddress = _apesTogetherAddress;
        _mint(msg.sender, 1);
    }

    function setApesTogetherAddress(address newApesTogetherAddress) external onlyOwner {
        apesTogetherAddress = newApesTogetherAddress;
    }

    modifier callerIsUser() {
        if (msg.sender != tx.origin) {
            revert ContractCaller();
        }
        _;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setContractURI(string memory newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }

    function setPrice(uint256 newprice) external onlyOwner {
        price = newprice;
    }

    function setExchangeRate(uint256 newExchangeRate) external onlyOwner {
        exchangeRate = newExchangeRate;
    }

    function setSupply(uint256 newsupply) external onlyOwner {
        supply = newsupply;
    }

    function setSignerAddress(address newSignerAddress) external onlyOwner {
        if (newSignerAddress == address(0)) revert ZeroAddress();
        signerAddress = newSignerAddress;
    }

    function setWithdrawAddress(address newWithdrawAddress) external onlyOwner {
        if (newWithdrawAddress == address(0)) revert ZeroAddress();
        withdrawAddress = newWithdrawAddress;
    }

    function setSaleActive(bool newIsSaleActive) external onlyOwner {
        isSaleActive = newIsSaleActive;
    }

    function setClaimActive(bool newIsClaimActive) external onlyOwner {
        isClaimActive = newIsClaimActive;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert ZeroBalance();
        if (withdrawAddress == address(0)) revert NoWithdrawAddress();
        payable(withdrawAddress).transfer(balance);
    }

    function verifySignature(uint16 amount, bytes memory _signature) public view returns (bool) {
        if (_signature.length != 65) revert InvalidSignatureLength();

        bytes32 messageHash = keccak256(abi.encodePacked(amount, msg.sender));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(ethSignedMessageHash, v, r, s) == signerAddress;
    }

    function reservedSupply() public view returns (uint256) {
        uint256 totalSupply = IERC721A(apesTogetherAddress).totalSupply();
        return totalSupply * exchangeRate;
    }

    function mint(uint16 maxAmount, uint16 mintAmount, bytes calldata mintSignature)
        external
        payable
        nonReentrant
        callerIsUser
    {
        if (!isSaleActive) revert SaleNotActive();
        if (mintAmount == 0) revert InvalidInput();
        if (totalSupply() + mintAmount + reservedSupply() > supply) {
            revert MaxSupplyReached();
        }
        if (msg.value != price * mintAmount) revert InvalidPayment();
        if (_getAux(msg.sender) + mintAmount > maxAmount) revert AllocationExceeded();
        if (!verifySignature(maxAmount, mintSignature)) revert InvalidSignature();
        _setAux(msg.sender, (_getAux(msg.sender)) + uint64(mintAmount));
        _mint(msg.sender, mintAmount);
    }

    function claim(uint256[] memory apesTogetherIds) external nonReentrant callerIsUser {
        if (!isClaimActive) revert ClaimNotActive();

        uint256 numTokens = apesTogetherIds.length;
        if (numTokens == 0) revert InvalidInput();
        for (uint16 i = 0; i < numTokens; i++) {
            IERC721A(apesTogetherAddress).safeTransferFrom(msg.sender, BURN_ADDRESS, apesTogetherIds[i]);
        }
        uint256 mintAmount = numTokens * exchangeRate;
        _mint(msg.sender, mintAmount);
    }
}
