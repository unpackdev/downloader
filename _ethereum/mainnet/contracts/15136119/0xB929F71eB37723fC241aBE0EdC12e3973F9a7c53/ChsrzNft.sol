//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721Enumerable.sol";

contract ChsrzNft is Ownable, Pausable, ERC721, ERC721Enumerable {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    // Step price parameters
    uint256 public _step1Price = 0 ether;
    uint256 public _step2Price = 0 ether;
    uint256 public _step3Price = 0 ether;

    // Whales parameters
    uint256 public _maxSupply = 3650;
    uint256 public _maxPerWallet = 1;
    uint256 public _maxMintPerTx = 1;

    // Mint step time parameters
    uint256 public _mintActiveAt = 1657765800; // July 13th, 7:30:00 PM PST
    uint256 public _step1Duration = 900; // 15 mins
    uint256 public _step2Duration = 900; // 15 mins
    uint256 public _step3Duration = 0; // Forever

    // Mint step specific parameters
    address public _step1RefNft;
    bytes32 public _step2MerkleRoot;
    mapping(address => uint256) public _mintCount;

    // Token uri parameters
    string public _baseUri;
    string public _unrevealUri;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    modifier onlyMintable(uint256 numberOfTokens) {
        require(numberOfTokens > 0, "Greater than 0");
        require(
            _maxPerWallet == 0 ||
                _mintCount[_msgSender()] + numberOfTokens <= _maxPerWallet,
            "Exceeded wallet max"
        );
        require(
            _maxMintPerTx == 0 || numberOfTokens <= _maxMintPerTx,
            "Exceeded tx max"
        );
        require(
            _maxSupply == 0 || totalSupply() + numberOfTokens <= _maxSupply,
            "Exceeded max"
        );

        _;
    }

    /**
     * @notice Mint nfts
     */
    function mint(uint256 mintAmount_, bytes32[] calldata proof)
        external
        payable
        whenNotPaused
        onlyMintable(mintAmount_)
    {
        require(block.timestamp >= _mintActiveAt, "Wait more");
        uint256 nftPrice = 0;
        if (
            _step1Duration == 0 ||
            block.timestamp < _mintActiveAt + _step1Duration
        ) {
            // step1
            require(
                IERC1155(_step1RefNft).balanceOf(_msgSender(), 1) > 0,
                "Step1 nop"
            );
            nftPrice = _step1Price;
        } else if (
            _step2Duration == 0 ||
            block.timestamp < _mintActiveAt + _step1Duration + _step2Duration
        ) {
            // step2
            require(
                IERC1155(_step1RefNft).balanceOf(_msgSender(), 1) > 0 ||
                    MerkleProof.verify(
                        proof,
                        _step2MerkleRoot,
                        keccak256(abi.encodePacked(_msgSender()))
                    ),
                "Step2 nop"
            );
            nftPrice = _step2Price;
        } else {
            nftPrice = _step3Price;
        }
        require(msg.value >= nftPrice * mintAmount_, "Insufficient funds");
        _mintCount[_msgSender()] = _mintCount[_msgSender()] + mintAmount_;
        _mintLoop(_msgSender(), mintAmount_);
    }

    /**
     * @notice Admin airdrop nfts to the users
     */
    function batchAirdrop(
        uint256[] calldata numberOfTokens_,
        address[] calldata recipients_
    ) external onlyOwner {
        require(numberOfTokens_.length == recipients_.length);

        for (uint256 i = 0; i < recipients_.length; i++) {
            _mintLoop(recipients_[i], numberOfTokens_[i]);
        }
    }

    function _mintLoop(address receiver_, uint256 mintAmount_) internal {
        require(
            _maxSupply > 0 ? totalSupply() + mintAmount_ <= _maxSupply : true,
            "Exceed max supply"
        );
        for (uint256 i = 0; i < mintAmount_; i++) {
            uint256 mintIndex = totalSupply() + 1;
            _safeMint(receiver_, mintIndex);
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pauseMint() external onlyOwner {
        super._pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpauseMint() external onlyOwner {
        super._unpause();
    }

    /**
     * @notice Set NFT price by steps
     */
    function setPrices(
        uint256 step1Price_,
        uint256 step2Price_,
        uint256 step3Price_
    ) external onlyOwner {
        _step1Price = step1Price_;
        _step2Price = step2Price_;
        _step3Price = step3Price_;
    }

    /**
     * @notice Set step durations
     */
    function setDurations(
        uint256 step1Duration_,
        uint256 step2Duration_,
        uint256 step3Duration_
    ) external onlyOwner {
        _step1Duration = step1Duration_;
        _step2Duration = step2Duration_;
        _step3Duration = step3Duration_;
    }

    /**
     * @notice Set setp1 refered nft address
     */
    function setStep1RefNft(address refNft_) external onlyOwner {
        _step1RefNft = refNft_;
    }

    /**
     * @notice Set setp2 merkle root for the whitelisted mint
     */
    function setStep2MerkleRoot(bytes32 root_) public onlyOwner {
        _step2MerkleRoot = root_;
    }

    /**
     * @notice Set mint limit per tx
     */
    function setWhalesConf(uint256 maxPerTx_, uint256 maxPerWallet_)
        external
        onlyOwner
    {
        _maxMintPerTx = maxPerTx_;
        _maxPerWallet = maxPerWallet_;
    }

    /**
     * @notice Set NFT active time
     */
    function setMintActiveTime(uint256 time_) external onlyOwner {
        require(time_ > block.timestamp, "Invalid time");
        _mintActiveAt = time_;
    }

    /**
     * @notice Set max supply
     */
    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        _maxSupply = maxSupply_;
    }

    /**
     * @notice Set base URI
     */
    function setBaseUri(string memory uri_) external onlyOwner {
        _baseUri = uri_;
    }

    /**
     * @notice Set unreveal URI
     */
    function setUnrevealUri(string memory uri_) external onlyOwner {
        _unrevealUri = uri_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    /**
     * @notice Get token uri for token id
     */
    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId_),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(_baseUri).length > 0
                ? string(abi.encodePacked(_baseUri, tokenId_.toString()))
                : _unrevealUri;
    }

    //to recieve ETH
    receive() external payable {}

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice withdraw collected ETH
     */
    function withdraw() external onlyOwner {
        uint256 etherBalance = address(this).balance;
        require(etherBalance > 0, "Insufficient ether balance");
        payable(_msgSender()).transfer(etherBalance);
    }

    /**
     * @notice It allows the admin to recover tokens sent to the contract
     * @param token_: the address of the token to withdraw
     * @param amount_: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverTokens(address token_, uint256 amount_) external onlyOwner {
        IERC20(token_).safeTransfer(_msgSender(), amount_);
    }
}
