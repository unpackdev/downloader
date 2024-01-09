//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./draft-EIP712.sol";
import "./PaymentSplitter.sol";

contract Collection is ERC1155, Ownable, PaymentSplitter, EIP712 {
    string private constant SIGNING_DOMAIN = "LazyNFT-Voucher";
    string private constant SIGNATURE_VERSION = "1";

    string public name;
    string public symbol;
    uint256 public maxSupply;
    uint256 public totalSupply;

    uint256 private startingAt;
    uint256 private initialPrice;

    // Mapping from token ID to copies
    mapping(uint256 => uint256) private copiesOf;

    // Mapping from token ID to initial price
    mapping(uint256 => uint256) private price;

    struct NFTVoucher {
        uint256 tokenId;
        uint256 maxSupply;
        string uri;
        bytes signature;
    }

    event NFTMinted(address, address, uint256, string);
    event NFTTransfered(address, address, uint256);

    constructor(
        uint256 _startingAt,
        uint256 _maxSupply,
        uint256 _initialPrice,
        string memory _uri,
        string memory _name,
        string memory _symbol,
        address _artist,
        address[] memory _payees,
        uint256[] memory _shares
    ) payable ERC1155(_uri) PaymentSplitter(_payees, _shares) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        name = _name;
        symbol = _symbol;
        maxSupply = _maxSupply;
        startingAt = _startingAt;
        initialPrice = _initialPrice;

        transferOwnership(_artist);
    }

    function mint(address _redeemer, NFTVoucher calldata _voucher) public payable {
        require(startingAt < block.timestamp, "Not started");
        require(copiesOf[_voucher.tokenId] < 1, "Already minted");

        // make sure signature is valid and get the address of the signer
        address signer = _verify(_voucher);

        // make sure that the signer is authorized to mint NFTs
        require(signer == owner(), "Signature invalid or unauthorized");

        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(msg.value >= initialPrice, "Insufficient funds to mint");

        copiesOf[_voucher.tokenId] = 1;
        totalSupply = totalSupply + 1;

        // first assign the token to the signer, to establish provenance on-chain
        _mint(signer, _voucher.tokenId, 0, "");

        // transfer the token to the redeemer
        _mint(_redeemer, _voucher.tokenId, 1, "");

        emit NFTMinted(signer, _redeemer, _voucher.tokenId, _voucher.uri);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        _safeTransferFrom(from, to, id, amount, data);

        emit NFTTransfered(from, to, id);
    }

    function _verify(NFTVoucher calldata voucher) private view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function _hash(NFTVoucher calldata voucher) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("NFTVoucher(uint256 tokenId,uint256 maxSupply,string uri)"),
                        voucher.tokenId,
                        voucher.maxSupply,
                        keccak256(bytes(voucher.uri))
                    )
                )
            );
    }
}