// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

struct Voucher {
    uint256 allowance;
    uint256 id;
    address wallet;
    bytes signature;
}
enum MintMode {
    Closed,
    VoucherOnly,
    Open
}

contract CryptoGangsCannaCollection is ERC721A, EIP712, Ownable {
    uint256 public maxTokens = 2100;
    uint256 public cap = 2100;
    uint256 public tokenPrice = 42000000000000000;
    string _baseTokenURI = "https://cryptogangsofficial.com/cgcc/";

    MintMode public mintMode = MintMode.Closed;
    address public voucherSigner;

    mapping(uint256 => uint256) public voucherBalance;

    constructor()
        ERC721A("CryptoGangsCannaCollection", "CGCC")
        EIP712("CGCC", "1")
    {}

    function mint(uint256 n) public payable {
        require(mintMode == MintMode.Open, "Public mint is closed");
        require(n <= 20, "Too many tokens");
        require(msg.value >= tokenPrice * n, "Didn't send enough ETH");
        require(
            totalSupply() + n <= maxTokens,
            "Can't fulfill requested tokens"
        );
        require(totalSupply() + n <= cap, "Can't fulfill requested tokens");

        _safeMint(msg.sender, n);
    }

    function mintWithVoucher(uint256 n, Voucher calldata voucher)
        public
        payable
    {
        require(mintMode != MintMode.Closed, "Minting is closed");
        require(msg.value >= tokenPrice * n, "Didn't send enough ETH");
        require(
            totalSupply() + n <= maxTokens,
            "Can't fulfill requested tokens"
        );
        require(
            voucherBalance[voucher.id] + n <= voucher.allowance,
            "Voucher doesn't have enough allowance"
        );
        require(totalSupply() + n <= cap, "Can't fulfill requested tokens");
        require(voucher.wallet == msg.sender, "This is not your voucher");
        require(verifyVoucher(voucher) == voucherSigner, "Invalid voucher");

        voucherBalance[voucher.id] += n;
        _safeMint(msg.sender, n);
    }

    function airdrop(address[] memory addr, uint256[] memory amounts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addr.length; i++) {
            require(
                totalSupply() + amounts[i] <= maxTokens,
                "Can't fulfill requested tokens"
            );
            _safeMint(addr[i], amounts[i]);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setTokenPrice(uint256 _price) external onlyOwner {
        tokenPrice = _price;
    }

    function setCap(uint256 _cap) external onlyOwner {
        cap = _cap;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getBaseURI() external view onlyOwner returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setMintMode(MintMode mode) external onlyOwner {
        mintMode = mode;
    }

    function setVoucherSigner(address signer) external onlyOwner {
        voucherSigner = signer;
    }

    function startPresale(uint256 price, address signer) external onlyOwner {
        tokenPrice = price;
        voucherSigner = signer;
        mintMode = MintMode.VoucherOnly;
    }

    function endPresale() external onlyOwner {
        voucherSigner = address(0x0);
        mintMode = MintMode.Closed;
    }

    function startPublicSale(uint256 price) external onlyOwner {
        tokenPrice = price;
        mintMode = MintMode.Open;
    }

    function hashVoucher(Voucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Voucher(uint256 allowance,uint256 id,address wallet)"
                        ),
                        voucher.allowance,
                        voucher.id,
                        voucher.wallet
                    )
                )
            );
    }

    function verifyVoucher(Voucher calldata voucher)
        public
        view
        returns (address)
    {
        bytes32 digest = hashVoucher(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }
}
