/*

                                                             ▐
                                                             ██
                                                            ████
                                                          ▄██████Ç
                                                ,▄▄▄███████████████▄
                                         ,▄▄███████████████████████████▄L
                                     ▄▄████████████████████████████████▀▀⌠'
                                  ▄████████████▀▀▀▀▀▀▀▀▀███████████▀⌠
                               ▄███████▀▀⌠ ,▄▄███▄        ▀██████▀
                             ▄█████▀⌠    ▄███████          ╙████
                           .████▀       █████████           "██
                          ▄██▀         ████    ▀██▄▄╓▄▄█W    █w
                         ╔██           ███       ████████    J
                         █▀           ¬███        ██,,███▄
                        ▐█             ███▄▄▄     ▐████▀
                        █              ╚█▄▄╓▄▀    ▐███▄ ▄
                        █               ╙███      █████
                         ▀▄               ▀███▄▄▄██████▀
                           ▀█▄▄L           ▄█████████▀
                              ▀▀████████████████▀▀⌠
                                      '⌠⌠'

 ___  ________  ___  ___  ___  __    ________  ________   ________        ___  ___
|\  \|\   __  \|\  \|\  \|\  \|\  \ |\   __  \|\   ___  \|\   ___ \      |\  \|\  \
\ \  \ \  \|\  \ \  \\\  \ \  \/  /|\ \  \|\  \ \  \\ \  \ \  \_|\ \     \ \  \ \  \
 \ \  \ \   _  _\ \  \\\  \ \   ___  \ \   __  \ \  \\ \  \ \  \ \\ \  __ \ \  \ \  \
  \ \  \ \  \\  \\ \  \\\  \ \  \\ \  \ \  \ \  \ \  \\ \  \ \  \_\\ \|\  \\_\  \ \  \
   \ \__\ \__\\ _\\ \_______\ \__\\ \__\ \__\ \__\ \__\\ \__\ \_______\ \________\ \__\
    \|__|\|__|\|__|\|_______|\|__| \|__|\|__|\|__|\|__| \|__|\|_______|\|________|\|__|
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

/// @title The World of Irukandji
/// @author bayu (github.com/pyk)
/// @notice A face, a brand, and a lifestyle by @yourbae
contract Irukandji is ERC721, ERC721Pausable, Ownable {

    /// ███ Storages █████████████████████████████████████████████████████████

    /// @notice Supply distribution
    uint256 public maxSupply = 8888;
    uint256 public maxMint = 2;
    uint256 public teamReserve = 160;

    /// @notice Minting price
    uint256 public presalePrice = 0.088 ether;
    uint256 public publicPrice = 0.130 ether;

    /// @notice Sale timestamp
    uint256 public presaleTimestamp;
    uint256 public publicTimestamp;

    /// @notice Whitelist claimed storage
    mapping(address => bool) internal claimed;
    mapping(address => uint256) internal mintAmountData;

    /// @notice Merkle root
    bytes32 public root;

    /// @notice Total supply tracker
    uint256 public totalSupply = 0;
    uint256 public totalReserved = 0;

    /// @notice Base URI and Contract URI
    string public baseURI;
    string public contractURI;

    /// @notice Custom token URI
    mapping(uint256 => string) internal customURI;

    /// @notice Team wallet address
    address public teamWallet;


    /// ███ Events ███████████████████████████████████████████████████████████

    event PriceUpdated(uint256 pre, uint256 pub);
    event MaxMintUpdated(uint256 newAmount);
    event SaleTimestampUpdated(uint256 pre, uint256 pub);
    event TeamReserveUpdated(uint256 newAmount);
    event CustomURIConfigured(uint256 tokenID, string uri);
    event URIConfigured(string b, string c);
    event MerkleRootUpdated();


    /// ███ Errors ███████████████████████████████████████████████████████████

    error InvalidTimestamp();
    error InvalidProof();
    error UserAlreadyClaimed();
    error MintPriceInvalid(uint256 expected, uint256 got);
    error MintAmountInvalid(uint256 maxMint, uint256 got);
    error OutOfStock();
    error WithdrawFailed();


    /// ███ Constructor ██████████████████████████████████████████████████████

    constructor(
        uint256 _presaleTimestamp,
        uint256 _publicTimestamp,
        bytes32 _root,
        string memory _baseURI,
        string memory _contractURI,
        address _teamWallet
    ) ERC721("Irukandji", "KANDJI") {
        // Set storages
        presaleTimestamp = _presaleTimestamp;
        publicTimestamp = _publicTimestamp;
        root = _root;
        baseURI = _baseURI;
        contractURI = _contractURI;
        teamWallet = _teamWallet;

        // Transfer ownership to teamWallet
        _transferOwnership(teamWallet);

        // Mint tokenID 1 to teamWallet
        totalSupply++;
        _mint(teamWallet, totalSupply);
    }


    /// ███ Owner actions ████████████████████████████████████████████████████

    /// @notice Set mint price
    /// @param _presale New presale price
    /// @param _public New public sale price
    /// @dev Only owner can call this function
    function setPrice(
        uint256 _presale,
        uint256 _public
    ) external onlyOwner {
        presalePrice = _presale;
        publicPrice = _public;
        emit PriceUpdated(_presale, _public);
    }

    /// @notice Set max mint
    /// @param _amount Max mint amount per tx
    /// @dev Only owner can call this function
    function setMaxMint(uint256 _amount) external onlyOwner {
        maxMint = _amount;
        emit MaxMintUpdated(_amount);
    }

    /// @notice Set sale timestamp value
    /// @param _presale Presale timestamp
    /// @param _public Public sale timestamp
    /// @dev Only owner can call this function
    function setSaleTimestamp(
        uint256 _presale,
        uint256 _public
    ) external onlyOwner {
        uint256 ts = block.timestamp;
        if (ts > _presale || ts > _public) revert InvalidTimestamp();
        presaleTimestamp = _presale;
        publicTimestamp = _public;
        emit SaleTimestampUpdated(_presale, _public);
    }

    /// @notice Set teamReserve value
    /// @param _amount The team reserve amount
    /// @dev Only owner can call this function
    function setTeamReserve(uint256 _amount) external onlyOwner {
        teamReserve = _amount;
        emit TeamReserveUpdated(_amount);
    }

    /// @notice Set the base URI
    /// @param _base The Base URI
    /// @param _contract The Contract URI
    /// @dev Only owner can call this function
    function setURI(
        string memory _base,
        string memory _contract
    ) external onlyOwner {
        baseURI = _base;
        contractURI = _contract;
        emit URIConfigured(_base, _contract);
    }

    /// @notice Set the custom token URI
    /// @dev Only owner can call this function
    function setCustomTokenURI(
        uint256 _tokenId,
        string memory _uri
    ) external onlyOwner {
        customURI[_tokenId] = _uri;
        emit CustomURIConfigured(_tokenId, _uri);
    }

    /// @notice Set the merkle root
    /// @dev Only owner can call this function
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
        emit MerkleRootUpdated();
    }

    /// @notice Mint reserve
    /// @dev Only owner can call this function
    function mintReserve(
        uint256 _amount,
        address _recipient
    ) external onlyOwner {
        // Checks
        if (totalSupply + _amount > maxSupply) revert OutOfStock();
        if (totalReserved + _amount > teamReserve) revert OutOfStock();

        for (uint256 i = 0; i < _amount; i++) {
            // Effects
            totalSupply++;
            totalReserved++;

            // Interaction
            _mint(_recipient, totalSupply);
        }
    }

    /// @notice Pause the contract
    /// @dev Only owner can call this function
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract
    /// @dev Only owner can call this function
    function unpause() external onlyOwner {
        _unpause();
    }


    /// ███ User actions █████████████████████████████████████████████████████

    /// @notice Presale mint
    /// @param _proof Merkle Tree leaf proof for msg.sender
    function presaleMint(bytes32[] calldata _proof) external payable {
        // Checks
        bool isValidProof = MerkleProof.verify(
            _proof,
            root,
            convertAddressToBytes32(msg.sender)
        );
        if (!isValidProof) revert InvalidProof();
        if (msg.value != presalePrice) {
            revert MintPriceInvalid({
                expected: presalePrice,
                got: msg.value
            });
        }
        if (totalSupply + 1 > maxSupply) revert OutOfStock();
        uint256 ts = block.timestamp;
        if (ts < presaleTimestamp || ts >= publicTimestamp) {
            revert InvalidTimestamp();
        }
        if (claimed[msg.sender]) revert UserAlreadyClaimed();

        // Effects
        claimed[msg.sender] = true;
        totalSupply++;

        // Interaction
        _mint(msg.sender, totalSupply);
    }

    /// @notice Public mint
    /// @param _amount The amount of kandjis
    function publicMint(uint256 _amount) external payable {
        // Checks
        uint256 mintedAmount = mintAmountData[msg.sender];
        if (mintedAmount + _amount > maxMint) {
            revert MintAmountInvalid({
                maxMint: maxMint,
                got: mintedAmount + _amount
            });
        }
        if (msg.value != (publicPrice * _amount)) {
            revert MintPriceInvalid({
                expected: publicPrice * _amount,
                got: msg.value
            });
        }
        if (totalSupply + _amount > (maxSupply - teamReserve)) revert OutOfStock();
        if (block.timestamp < publicTimestamp) revert InvalidTimestamp();

        for (uint256 i = 0; i < _amount; i++) {
            // Effects
            totalSupply++;
            mintAmountData[msg.sender]++;

            // Interaction
            _mint(msg.sender, totalSupply);
        }
    }

    /// @notice Send ETH inside the contract to Irukandji team wallet
    function withdraw() external {
        (bool success, ) = teamWallet.call{
            value: address(this).balance
        }("");
        if (!success) revert WithdrawFailed();
    }

    /// @notice Send ETH inside the contract to Irukandji team wallet
    function withdraw(uint256 _amount) external {
        (bool success, ) = teamWallet.call{ value: _amount }("");
        if (!success) revert WithdrawFailed();
    }


    /// ███ Internal functions ███████████████████████████████████████████████

    /// @notice Convert address to bytes32
    function convertAddressToBytes32(
        address _addy
    ) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addy))); // https://ethereum.stackexchange.com/a/41356
    }

    /// @notice Implement pausable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    /// ███ External functions ███████████████████████████████████████████████

    /// @notice Returns metadata for each tokenID
    function tokenURI(
        uint256 tokenID
    ) public view virtual override returns (string memory) {
        if (tokenID == 0 || tokenID > totalSupply) return "";
        bytes32 uri = keccak256(abi.encodePacked(customURI[tokenID]));
        if (uri != keccak256(abi.encodePacked(""))) {
            // Custom URI
            return customURI[tokenID];
        } else {
            // Use global URI
            return string(
                abi.encodePacked(
                    baseURI,
                    "/",
                    Strings.toString(tokenID),
                    ".json"
                )
            );
        }
    }
}
