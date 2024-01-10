// SPDX-License-Identifier: GPL-3.0

/**
 * @title Complete the Punks: Project
 * @dev Per-project contract for managing Bodies + Legs
 * @author earlybail.eth | Cranky Brain Labs
 * @notice #GetBodied #LegsFuknGooo
 */

/*
                   ;╟██▓▒              :╟██▓▒
                ,φ▒╣╬╬╩╩Γ               ╙╩╬╬╬▓▒░
              ,╓φ╣▓█╬Γ                     ╚╣█▓╬▒╓,                ,,╓╓╓╓,
             φ╣▓▓╬╩""                       ""╚╣▓▓▒░              ]╟▓████▓▒
          φφ╬╬╬╬╩╙                            '╚╩╬╬╬▒▒░           φ╫███▓╬╬╬▓▒░
         ]╟▓█▓▒                                  :╟▓█▓▒           φ╫██╬▒ ╚╣█▓╬φ,,
         :╟██▓▒                                  :╟██▓▒           φ╫██▓▒  "╙╠╣▓▓▒░
         :╟██▓▒                                  :╟██▓▒     φφ▒▒▒▒╬╬╬╩╩'    φ╫██▓▒
         :╟██▓▒      ,,,                         :╟██▓▒    ]╟▓████▓╬⌐       φ╫██▓▒
         :╟██▓▒    .╠╣▓▓▒                        :╟██▓▒    :╟███╬╩"'        φ╫██▓▒
         :╟██▓▒    :╟██▓▒     φφ▒φ░        ,φ▒▒░ :╟██▓▒    :╟██▓▒           φ╫██▓▒
         :╟██▓▒    :╟██▓▒    '╠▓█▓▒        ╚╣█▓╬⌐:╟███▒≥,  '╠▓█▓╬≥,       ,,φ╣██╬░
         :╟██▓▒    :╟██▓▒     ^"╙"'         "╙╙" :╟█████▓▒~ ^"╙╠╣▓▓▒~    φ╣▓▓╬╩╙"
         :╟██▓▒    :╟██▓▒                        :╟████▓╬╬▒▒φ  ╠▓██╬[    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟███▒ ╚╟▓█╬▒╓╠▓██╬[    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟██▓▒  "╙╚╣▓▓████╬[    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟██▓▒     ╚╬╬████╬[    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟███▒╓,      ╚╣██╬⌐    ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟█████▓▒~    '"╙╙"     ╠▓██╬[
         :╟██▓▒    :╟██▓▒                        :╟████▓╬╬▒▒φ         ≤φ▒╬╬╬╬╚
         :╟██▓▒    :╟██▓▒                        :╟███▒ ╚╣██╬▒,,,,,,,φ╟▓█▓╩
         :╟██▓▒    :╟██▓▒                        :╟██▓▒  "╙╩╬╣▓▓▓▓▓▓▓▓╬╬╚╙'
         :╟██▓▒    :╟██▓▒                        :╟██▓▒     ╚╬▓▓▓▓▓▓▓╬╩░
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒                        :╟██▓▒
         :╟██▓▒    :╟██▓▒           ]φ╣▓▒░       :╟██▓▒
         :╟██▓▒    :╟██▓▒           "╠╬▓╩░       :╟██▓▒
         :╟███▒,   :╟██▓▒                        :╟██▓▒
         :╟████▓▒▒ :╟██▓▒                        :╟██▓▒
          ╚╬█████▓▒▒╣██▓▒                        :╟██▓▒
            "╠▓████████▓▒                        :╟██▓▒
*/

/*
                φ╫██▓▒                           :╟██▓▒
                φ╫██▓▒    ,φ▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒░    :╟██▓▒
                φ╫██▓▒    φ╣███████████████▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓╩╙╙╙╙╙╙╙╚╣██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    φ╫██▓▒       :╟██▓▒    :╟██▓▒
                φ╫██▓▒    "╩╬▓╬▒φφ,    :╟██▓▒     ╚╬▓╬╬▒φε
                φ╫██▓▒       7╟▓█▓▒,   ;╟██▓▒       `╠╣█▓╬░
                φ╫██▓▒        "╙╩╬╣▓▓▓▓▓███▓▒        ^╙╩╬╣▓▓▓▓▓▒░
                φ╫██▓▒           ╚╠╣███████▓▒           "╠╬████╬╬▒φε
                φ╫██▓▒              ```╠╠███▒,             ```░╠╣██╬[
                φ╫████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████╬[
                "╠╬███████████████████████████████████████████████╬╩
                  `^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*/

// Directives.
pragma solidity 0.8.9;

// Third-party deps.
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Context.sol";
import "./MerkleProof.sol";

// Local deps.
import "./Bodies.sol";
import "./Legs.sol";

// Contract.
contract Project is ReentrancyGuard, Ownable, PaymentSplitter {
    // Events.
    event StatusChange(Status _newStatus);

    // Mint statuses.
    enum Status {
        Paused,
        Whitelist,
        Mintpass,
        Public
    }

    // Current mint status, defaults to Status[0] (Paused).
    Status public status;

    // Bodies.
    Bodies public bodies;

    // Legs.
    Legs public legs;

    // Pricing.
    // @notice settable, use mintPrice() for latest.
    uint256 public whitelistPrice = 0.02 ether;
    uint256 public mintpassPrice = 0.04 ether;
    uint256 public publicPrice = 0.04 ether;

    // Mint limits.
    // @notice settable, use mintLimit() for latest.
    uint256 public whitelistMintLimit = 4;
    uint256 public mintpassMintLimit = 20;
    uint256 public publicMintLimit = 40;

    // Max tokens.
    uint256 public maxSupply = 10000;

    // Mintpassed contracts.
    address[] public mintpassedContracts;

    // Whitelist Merkle root.
    bytes32 public merkleRoot = 0x05ba199ba71527baf0f85acf24728a2e559447f3228c1ff56d0d90f8bb269f7d;

    // Constructor.
    constructor (
        string memory _name,
        string memory _symbol,
        uint256 _tokenStartId,
        address[] memory _payees,
        uint256[] memory _shares
    ) PaymentSplitter(_payees, _shares) {
        // Deploy and set Bodies contract.
        bodies = new Bodies(
            string(abi.encodePacked(_name, ": Bodies")), // Extend name.
            string(abi.encodePacked(_symbol, "B")), // Extend symbol.
            _tokenStartId
        );

        // Set this Project contract as parent project.
        bodies.setProjectAddress(address(this));

        // Transfer bodies contract ownership to deployer.
        bodies.transferOwnership(_msgSender());

        // Deploy and set Legs contract.
        legs = new Legs(
            string(abi.encodePacked(_name, ": Legs")), // Extend name.
            string(abi.encodePacked(_symbol, "L")), // Extend symbol.
            _tokenStartId
        );

        // Set this Project contract as parent project.
        legs.setProjectAddress(address(this));

        // Transfer legs contract ownership to deployer.
        legs.transferOwnership(_msgSender());
    }

    // Mint check helper.
    modifier mintCheck (address _to, uint256 _numToMint) {
        // Early bail if paused.
        require(status != Status.Paused, "Minting is paused");

        // Ensure sender.
        require(_to == _msgSender(), "Can only mint for self");

        // Protect against contract minting.
        require(!Address.isContract(_msgSender()), "Cannot mint from contract");

        // Ensure non-zero mint amount.
        require(_numToMint > 0, "Cannot mint zero tokens");

        // Ensure available supply.
        require(totalSupply() + _numToMint <= maxSupply, "Max supply exceeded");

        // Ensure mint limit not exceeded.
        require(_numToMint <= mintLimit(), "Cannot mint this many tokens");

        // Ensure proper payment.
        require(msg.value == _numToMint * mintPrice(), "Incorrect payment amount sent");

        _;
    }

    // Set mint price.
    function setPrice (Status _status, uint256 _newPrice) external onlyOwner {
        if (_status == Status.Whitelist) {
            whitelistPrice = _newPrice;
        }

        if (_status == Status.Mintpass) {
            mintpassPrice = _newPrice;
        }

        if (_status == Status.Public) {
            publicPrice = _newPrice;
        }
    }

    // Set mint limit.
    function setMintLimit (Status _status, uint256 _newLimit) external onlyOwner {
        if (_status == Status.Whitelist) {
            whitelistMintLimit = _newLimit;
        }

        if (_status == Status.Mintpass) {
            mintpassMintLimit = _newLimit;
        }

        if (_status == Status.Public) {
            publicMintLimit = _newLimit;
        }
    }

    // Set the bodies contract.
    function setBodies (address _newAddr) external onlyOwner {
        bodies = Bodies(_newAddr);
    }

    // Set the legs contract.
    function setLegs (address _newAddr) external onlyOwner {
        legs = Legs(_newAddr);
    }

    // (Re-)set the whitelist Merkle root.
    function setMerkleRoot (bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
    }

    // Set the mint status.
    function setStatus (Status _newStatus) external onlyOwner {
        // Update.
        status = _newStatus;

        // Broadcast.
        emit StatusChange(_newStatus);
    }

    // (Re-)set the list of Mintpassed Contracts.
    function setMintpassedContracts (address[] calldata _newAddrs) external onlyOwner {
        delete mintpassedContracts;
        mintpassedContracts = _newAddrs;
    }

    // Add a new Mintpassed Contract.
    function addMintpassedContract (address _addr) external onlyOwner {
        mintpassedContracts.push(_addr);
    }

    // Check if an address is whitelisted via Merkle proof validation.
    function isWhitelistedAddress (address _addr, bytes32[] calldata _merkleProof) public view returns (bool) {
        // Verify Merkle tree proof.
        bytes32 leaf = keccak256(abi.encodePacked(_addr));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    // Check if an address is mintpassed (has a balance on a Mintpassed Contract).
    function isMintpassedAddress (address _addr) public view returns (bool) {
        // Cache array length to save gas.
        uint256 len = mintpassedContracts.length;

        // Loop through Mintpassed Contracts.
        for (uint256 i = 0; i < len; i++) {
            // Instantiate this Mintpassed Contract.
            MintpassedContract mintpassedContract = MintpassedContract(mintpassedContracts[i]);

            // Check if the address has a non-zero balance.
            if (mintpassedContract.balanceOf(_addr) > 0) {
                return true;
            }
        }

        // Not allowed.
        return false;
    }

    // Proxy supply to bodies.
    function totalSupply () public view returns (uint256) {
        return bodies.totalSupply();
    }

    // Proxy balance to bodies.
    function balanceOf (address _owner) public view returns (uint256) {
        return bodies.balanceOf(_owner);
    }

    // Dynamic mint price.
    function mintPrice () public view returns (uint256) {
        // Paused.
        if (status == Status.Paused) {
            // Failsafe, but if you find a way go for it.
            return 1000000 ether;
        }

        // Whitelist.
        if (status == Status.Whitelist) {
            return whitelistPrice;
        }

        // Mintpass.
        if (status == Status.Mintpass) {
            return mintpassPrice;
        }

        // Public.
        return publicPrice;
    }

    // Dynamic mint limit.
    function mintLimit () public view returns (uint256) {
        // Paused.
        if (status == Status.Paused) {
            return 0;
        }

        // Whitelist.
        if (status == Status.Whitelist) {
            return whitelistMintLimit;
        }

        // Mintpass.
        if (status == Status.Mintpass) {
            return mintpassMintLimit;
        }

        // Public.
        return publicMintLimit;
    }

    // Mint.
    function mint (address _to, uint256 _numToMint) external payable nonReentrant mintCheck(_to, _numToMint) {
        // Not for whitelist mints.
        require(status != Status.Whitelist, "Whitelist mints must provide proof via mintWhitelist()");

        // Mintpass.
        if (status == Status.Mintpass) {
            // Check eligibility.
            require(isMintpassedAddress(_to), "Address is not mintpassed");
        }

        // Okay mint.
        _mint(_to, _numToMint);
    }

    // Mint whitelist.
    function mintWhitelist (address _to, uint256 _numToMint, bytes32[] calldata _merkleProof) external payable nonReentrant mintCheck(_to, _numToMint) {
        // Require whitelist status.
        require(status == Status.Whitelist, "Whitelist mints only");

        // Check balance.
        require((balanceOf(_to) + _numToMint) <= mintLimit(), "Whitelist mint limit exceeded");

        // Check whitelist eligibility.
        require(isWhitelistedAddress(_to, _merkleProof), "Address is not whitelisted");

        // Okay mint.
        _mint(_to, _numToMint);
    }

    // Actually mint.
    function _mint (address _to, uint256 _numToMint) private {
        // Mint bodies & legs.
        bodies.mint(_to, _numToMint);
        legs.mint(_to, _numToMint);
    }
}

// Mintpassed Contract interface.
interface MintpassedContract {
    function balanceOf(address _account) external view returns (uint256);
}
