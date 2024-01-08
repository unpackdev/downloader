// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

struct Voucher {
    address wallet;
    uint256 nonce;
    bytes signature;
}

contract DawnBunnies is ERC721Enumerable, EIP712, Ownable {
    uint256 public maxItems;
    bool public paused = false;
	bool public started = false;
    address public voucherSigner;
    uint256 public totalMinted;
    string _baseTokenURI;
    mapping(uint256 => bool) public voucherUsed;

    constructor(
        string memory baseURI,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _maxItems,
        address _voucherSigner
    ) ERC721(tokenName, tokenSymbol) EIP712(tokenName, "1") {
        voucherSigner = _voucherSigner;
        maxItems = _maxItems;
        _baseTokenURI = baseURI;
    }

    // Mint items
    function mint(Voucher calldata voucher) public {
        require(!paused || msg.sender == owner(), "We're paused");
		require(started || msg.sender == owner(), "We haven't started yet");
        require(_verifyVoucher(voucher) == voucherSigner, "Invalid voucher");
        require(voucher.wallet == msg.sender, "This is not your voucher");
        require(
            !voucherUsed[voucher.nonce],
            "Whitelisted Winner already got 1 NFT"
        );
        require(totalMinted + 1 <= maxItems, "Can't fulfill requested items");

        totalMinted++;
        _safeMint(msg.sender, totalMinted);

        voucherUsed[voucher.nonce] = true;
    }

    // Mint n items to owner
    function devMint(uint256 n) external onlyOwner {
        require(totalMinted + n <= maxItems, "Can't fulfill requested items");
        for (uint256 i = 0; i < n; i++) {
            totalMinted++;
            _safeMint(msg.sender, totalMinted);
        }
    }

    // Get the base URI (internal)
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Set the base URI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // get all tokens owned by an address
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    // pause/unpause contract
    function pause(bool val) external onlyOwner {
        paused = val;
    }

	// start contract
    function start() external onlyOwner {
        started = true;
    }

    // withdraw balance
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _hashVoucher(Voucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("Voucher(address wallet,uint256 nonce)"),
                        voucher.wallet,
                        voucher.nonce
                    )
                )
            );
    }

    function _verifyVoucher(Voucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashVoucher(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    // Set voucher signer
    function setVoucherSigner(address addr) external onlyOwner {
        voucherSigner = addr;
    }
}
