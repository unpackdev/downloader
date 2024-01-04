// SPDX-License-Identifier: AGPL-3.0-only+VPL
pragma solidity ^0.8.16;

import "./ERC721A.sol";
import "./LibPack.sol";
import "./Ownable.sol";
import "./MerkleProofLib.sol";
import "./IShishi.sol";

/**
 *   @custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVM MEVM
 *   @title Shishi. Ever dream this girl?
 *   @author 0x_ultra
 *   @author many beautiful Shishis
 *   @custom:version 3.0
 *   @custom:third time's a charm
 *
 *   Shishi is a generative art project by shirosama.eth; yippiee!
 *
 *   @custom:date January 4thth, 2024.
 */
contract Shishi is ERC721A, IShishi, Ownable {
    using LibPack for *;

    /**
     * Store the provenance hash. This is computed as the keccak256 hash of the
     * list of metadatas for all Shishis, in token ID order. We understand that
     * this is only a weak guarantee of honesty--it proves that we committed to
     * the art and its order prior to beginning the mint but does nothing to
     * trustlessly conceal the specific metadata of particular Shishis ahead of
     * time. You'll just have to deal with that; schemes which apply
     * provably-randomized offsets to the provenance data are very difficult
     * to reconcile with instant reveals.
     */
    bytes32 private constant provenance = 0xfef66cef154a5d4dbed8c336934c23c383df7394ea03f033d7cfa81f7eacff5b;

    /// Track the base token metadata URI.
    string internal baseURI;

    /// Track whether the base token metadata URI is locked to future changes.
    bool private baseURILocked;

    /// Whether transfers can be paused / unpaused.
    bool public pausedLocked;

    /// Whether transfers are paused.
    bool public paused;

    /// Track the total supply cap on the number of Shishis that may be minted.
    uint256 private constant cap = 3520;

    uint256 maxPerWalletPublic = 2;

    // File extension for metadata
    string private fileExtension = ".json";

    /// Phase start times
    Phases public phasetimes;

    /// Merkle roots
    Roots public roots;

    /// Track the number of utilized FCFS Milady/Remilio mints.
    uint256 public fcfs;

    /**
     * Construct an instance of the Shishi contract.
     *
     * @param _owner The initial owner of this contract.
     * @param _initialBaseURI The initial base token metadata URI to use.
     * @param _phasetimes The initial phase times.
     * @param _roots The initial merkle roots.
     */
    constructor(address _owner, string memory _initialBaseURI, Phases memory _phasetimes, Roots memory _roots)
        ERC721A("Shishi", "SHISHI")
    {
        _initializeOwner(_owner);
        baseURI = _initialBaseURI;
        phasetimes = _phasetimes;
        roots = _roots;
        _mint(_owner, 1);
    }

    /**
     * Phase one mint (Oh I see and Shishi maker)
     *
     * @param _paidWant The number of paid Shishis to mint.
     * @param _freeWant The number of free Shishis to mint.
     * @param _paidMax The maximum number of paid Shishis that may be minted by the user.
     * @param _freeMax The maximum number of free Shishis that may be minted by the user.
     * @param proof The merkle proof.
     */
    function mintOne(uint8 _paidWant, uint8 _freeWant, uint8 _paidMax, uint8 _freeMax, bytes32[] calldata proof)
        external
        payable
    {
        Claimed memory claimed = claimedOne(msg.sender);
        _verifyMint(_paidWant, _freeWant, _paidMax, _freeMax, proof, phasetimes.startOne, roots.rootOne, claimed);
        claimed.paid += _paidWant;
        claimed.free += _freeWant;
        _setClaimedOne(msg.sender, claimed);

        _mint(msg.sender, _paidWant + _freeWant);

        emit PhaseOneMinted(msg.sender, _paidWant, _freeWant);
    }

    /**
     * Phase two mint (Miladys and Remilios)
     *
     * @param _paidWant The number of paid Shishis to mint.
     * @param _freeWant The number of free Shishis to mint.
     * @param _paidMax The maximum number of paid Shishis that may be minted by the user.
     * @param _freeMax The maximum number of free Shishis that may be minted by the user.
     * @param proof The merkle proof.
     */
    function mintTwo(uint8 _paidWant, uint8 _freeWant, uint8 _paidMax, uint8 _freeMax, bytes32[] calldata proof)
        external
        payable
    {
        Claimed memory claimed = claimedTwo(msg.sender);

        if (_freeWant > 0) {
            if (fcfs >= 300) {
                revert OutOfStock();
            } else {
                fcfs += _freeWant;
            }
        }

        _verifyMint(_paidWant, _freeWant, _paidMax, _freeMax, proof, phasetimes.startTwo, roots.rootTwo, claimed);
        claimed.paid += _paidWant;
        claimed.free += _freeWant;
        _setClaimedTwo(msg.sender, claimed);

        _mint(msg.sender, _paidWant + _freeWant);

        emit PhaseTwoMinted(msg.sender, _paidWant, _freeWant);
    }

    /**
     * Phase three mint (Public Mint)
     *
     * @param _amount The number of Shishis to mint.
     */
    function mintThree(uint8 _amount) external payable {
        if (block.timestamp < phasetimes.startThree) {
            revert NotStartedYet();
        }

        if (_totalMinted() + _amount > cap) {
            revert OutOfStock();
        }

        uint8 claimed = claimedThree(msg.sender);

        if (claimed + _amount > maxPerWalletPublic) {
            revert OutOfMints();
        }

        if (msg.value < uint256(_amount) * 0.04 ether) {
            revert NotEnoughPayment();
        }

        if (msg.sender != tx.origin) {
            uint8 claimedOrigin = claimedThree(tx.origin);
            if (claimedOrigin + _amount > maxPerWalletPublic) {
                revert OutOfMints();
            }
            _setClaimedThree(tx.origin, claimedOrigin + _amount);
        }

        _setClaimedThree(msg.sender, claimed + _amount);

        _mint(msg.sender, _amount);

        emit PhaseThreeMinted(msg.sender, _amount);
    }

    /**
     * Verifies that all conditions are met for the user to mint
     */
    function _verifyMint(
        uint8 _paidWant,
        uint8 _freeWant,
        uint8 _paidMax,
        uint8 _freeMax,
        bytes32[] calldata proof,
        uint256 _phase,
        bytes32 _root,
        Claimed memory claimed
    ) internal {
        if (block.timestamp < _phase) {
            revert NotStartedYet();
        }

        if (_totalMinted() + _paidWant + _freeWant > cap) {
            revert OutOfStock();
        }

        if (
            !MerkleProofLib.verifyCalldata(
                proof, _root, keccak256(abi.encodePacked(msg.sender, uint256(_paidMax), uint256(_freeMax)))
            )
        ) {
            revert CannotClaimInvalidProof();
        }

        if (claimed.paid + _paidWant > _paidMax || claimed.free + _freeWant > _freeMax) {
            revert OutOfMints();
        }

        if (msg.value < uint256(_paidWant) * 0.033 ether) {
            revert NotEnoughPayment();
        }
    }

    /**
     * Override the starting index of the first Shishi.
     *
     * @return _ The token ID of the first Shishi.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * Override the `_baseURI` used in our parent contract with our set value.
     *
     * @return _ The base token metadata URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Allows querying the URI for a given token ID.
     *
     * @param _tokenId uint256 ID of the token to query
     * @return URI of given token ID
     */
    function tokenURI(uint256 _tokenId) public view override(ERC721A) returns (string memory) {
        return string(abi.encodePacked(baseURI, _toString(_tokenId), fileExtension));
    }

    /**
     * Track Shishis minted by users during phase one.
     *
     * @return _ Shishis minted.
     */
    function claimedOne(address _address) public view returns (Claimed memory) {
        uint64 x = _getAux(_address);
        return Claimed({paid: x.get(0), free: x.get(1)});
    }

    /**
     * Track Shishis minted by users during phase two.
     *
     * @return _ Shishis minted.
     */
    function claimedTwo(address _address) public view returns (Claimed memory) {
        uint64 x = _getAux(_address);
        return Claimed({paid: x.get(2), free: x.get(3)});
    }

    /**
     * Track Shishis minted by users during phase three.
     *
     * @return _ Shishis minted.
     */
    function claimedThree(address _address) public view returns (uint8) {
        uint64 x = _getAux(_address);
        return x.get(4);
    }

    /**
     * Set Shishis minted by users during phase one.
     */
    function _setClaimedOne(address _address, Claimed memory _claimed) internal {
        _setAux(_address, _getAux(_address).set(0, _claimed.paid).set(1, _claimed.free));
    }

    /**
     * Set Shishis minted by users during phase two.
     */
    function _setClaimedTwo(address _address, Claimed memory _claimed) internal {
        _setAux(_address, _getAux(_address).set(2, _claimed.paid).set(3, _claimed.free));
    }

    /**
     * Set Shishis minted by users during phase three.
     */
    function _setClaimedThree(address _address, uint8 _claimed) internal {
        _setAux(_address, _getAux(_address).set(4, _claimed));
    }

    /**
     * Allow the contract owner to set the base token metadata URI.
     *
     * @param _newBaseURI The new base token metadata URI to set.
     * @custom:throws BaseURILocked if the base token metadata URI is locked
     *   against future changes.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        if (baseURILocked) {
            revert BaseURILocked();
        } else {
            baseURI = _newBaseURI;
        }
    }

    /**
     * Allow the contract owner to permanently lock base URI changes.
     */
    function lockBaseURI() external onlyOwner {
        baseURILocked = true;
    }

    /**
     * Allow the contract owner to set the whitelist phase times.
     *
     * @param _startOne The new phase one time.
     * @param _startTwo The new phase two time.
     * @param _startThree The new phase three time.
     */
    function setPhases(uint256 _startOne, uint64 _startTwo, uint64 _startThree) external onlyOwner {
        phasetimes = Phases(uint64(_startOne), _startTwo, _startThree);
    }

    /**
     * Allow the contract owner to set the whitelist roots.
     *
     * @param _rootOne The new phase one root.
     * @param _rootTwo The new phase two root.
     */
    function setRoots(bytes32 _rootOne, bytes32 _rootTwo) external onlyOwner {
        roots = Roots(_rootOne, _rootTwo);
    }

    /**
     * Allow the contract owner to set max amount of mints per wallet for public mint.
     *
     * @param _max The new max amount of mints per wallet.
     */
    function setMaxPerWalletPublic(uint256 _max) external onlyOwner {
        maxPerWalletPublic = _max;
    }

    /**
     * Allows the owner to sweep the contract balance.
     */
    function sweep(address _to) external onlyOwner {
        (bool success,) = payable(_to).call{value: address(this).balance}("");
        if (!success) revert SweepingTransferFailed();
    }

    /**
     * Allow the contract owner to permanently lock paused changes.
     */
    function lockPaused() external onlyOwner {
        pausedLocked = true;
    }

    /**
     * Allows the owner to pause / unpause transfers (including minting).
     */
    function setPaused(bool _paused) external onlyOwner {
        if (pausedLocked) {
            revert PausedLocked();
        } else {
            paused = _paused;
        }
    }

    /**
     * Overrides `ERC721A._beforeTokenTransfers` to revert if paused.
     */
    function _beforeTokenTransfers(address, address, uint256, uint256) internal virtual override {
        if (paused) revert Paused();
    }
}
