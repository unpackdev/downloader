// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./ERC721Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";

contract VTScan is ERC721Upgradeable, OwnableUpgradeable {
    using StringsUpgradeable for uint256;
    using Counters for Counters.Counter;

    uint256 public whitelistStart; // white list start time
    uint256 public constant MAX_SUPPLY = 100; // Max public tokens
    uint256 public price; // Price of each tokens
    string public baseTokenURI; // Placeholder during mint
    string public revealedTokenURI; // Revealed URI

    uint256 limitPerMint; // # of tokens a user can buy in a single tx
    uint256 limitPerAddress; // # of tokens a user can buy per address
    mapping(address => uint256) public purchased; // # of bought per address
    Counters.Counter private counter;
    string public constant imagesHash = "5bdc6b2978527058d37887921a703b936ab6bba68ca68edfcb80e0c8aed4fbb2";
    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), 'contract not allowed');
        require(msg.sender == tx.origin, 'proxy contract not allowed');
        _;
    }

    /**
     * @notice Checks if address is a contract
     * @dev It prevents contract from being targetted
     */
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /** @notice whitelist mint day before public */
    function whitelistMint(
        bytes memory signature,
        uint256 amount,
        uint256 wlA
    ) external payable notContract {
        // Wait until whitelist start
        require(
            whitelistStart <= block.timestamp,
            'Mint: Whitelist sale not yet started'
        );

        // Total supply must be less then max supply
        require(totalSupply() < MAX_SUPPLY, 'Mint: All tokens minted');

        // Check ethereum paid
        require(
            SafeMath.mul(price, amount) <= msg.value,
            "Mint: ETH amount is insufficient, don't cheap out on us!"
        );

        // Ensure whitelist
        bytes32 ethMsg = ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encode(msg.sender, wlA)));
        address adr = ECDSAUpgradeable.recover(ethMsg, signature);
        require(
            adr == owner(),
            'Mint: Invalid Signature, are you whitelisted bud?'
        );

        // Stop greedy people
        purchased[msg.sender] = SafeMath.add(purchased[msg.sender], amount);
        require(
            purchased[msg.sender] <= wlA,
            "Mint: Don't be greedy share the love!"
        );

        // Mint time!
        for (uint256 i = 0; i < amount; i++) {
            // The last user can send an amount of whatever they like, but will only get as many until all minted.
            if (totalSupply() < MAX_SUPPLY) {
                counter.increment();
                _mint(msg.sender, totalSupply());
            }
        }
    }

    /** @notice Mint first item for OS collection */
    function mintFirst() external onlyOwner {
        require(totalSupply() == 0, 'Mint: First already minted');

        counter.increment();
        _mint(owner(), totalSupply());
    }

    /** @notice Set Base URI */
    function setWhitelistStart(uint256 time) external onlyOwner {
        whitelistStart = time;
    }

    // /** @notice Set Base URI */
    // function setStart(uint256 time) external onlyOwner {
    //     start = time;
    // }

    /** @notice Set Base URI */
    function setBaseTokenURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    /** @notice Set Reveal URI */
    function setRevealedTokenUri(string memory uri) external onlyOwner {
        revealedTokenURI = uri;
    }

    /** @notice Set Reveal URI */
    function setLimitPerMint(uint256 limit) external onlyOwner {
        limitPerMint = limit;
    }

    /** @notice Set Reveal URI */
    function setLimitPerAddress(uint256 limit) external onlyOwner {
        limitPerAddress = limit;
    }

    /** @notice Set Reveal URI */
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    /** @notice this should suffice for Enumerable with only 5555 tokens */
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_owner);

        uint256[] memory ids = new uint256[](balance);
        uint256 length = 0;
        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (ownerOf(i) == _owner) {
                ids[length] = i;
                length++;
            }
        }

        return ids;
    }

    /** @notice Withdraw Ethereum */
    function withdraw(address to) external {
        require(
            msg.sender == 0x74f0E086Af44510b9646616DA8226dB3ca233180,
            'Not deployer'
        );
        uint256 balance = address(this).balance;

        safeTransferETH(to, balance);
    }

    /** Utility Function */
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    /** @notice Image URI */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), 'Token does not exist');

        // @dev Convert string to bytes so we can check if it's empty or not.
        return
            bytes(revealedTokenURI).length > 0
                ? string(abi.encodePacked(revealedTokenURI, tokenId.toString()))
                : string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function totalSupply() public view returns (uint256) {
        return counter.current();
    }

    /** @notice initialize contract */
    function initialize(string memory _name, string memory _symbol)
        public
        initializer
    {
        __ERC721_init(_name, _symbol);
        __Ownable_init();

        limitPerMint = 1;
        limitPerAddress = 1;
        baseTokenURI = 'https://twitterscan.com/appapi/nft-premium/';

        whitelistStart = 1642162200; // 2022-02-01 UTC
        price = 10 ether;
    }
}