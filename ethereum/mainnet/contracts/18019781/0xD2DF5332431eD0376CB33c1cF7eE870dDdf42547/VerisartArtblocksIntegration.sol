// SPDX-License-Identifier: MIT

import "./IArtblocksCore.sol";
import "./IAdminACLV1.sol";
import "./ECDSA.sol";

pragma solidity ^0.8.9;

contract VerisartArtblocksIntegration {
    bytes32 private constant _DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
        );

    bytes32 private _eip712DomainSeparator =
        keccak256(
            abi.encode(
                _DOMAIN_TYPEHASH,
                keccak256("Verisart"),
                keccak256("1"),
                block.chainid,
                address(this),
                0xf84c063feaae44fa2f4a846cf2dadc08b50b6a5b0b04bed3d70ed9fa1a199edc // Verisart's EIP712 salt
            )
        );

    bytes32 private constant _MINT_SIGNED_TYPEHASH =
        keccak256(
            "MintNFT(address sender,address to,uint256 projectId,address core,bytes32 tokenNonce)"
        );

    /**
     * @dev Allows minting via signed mint (an off-chain signature is still required).
     *      By default, this is enabled for all projects/cores.
     *      This can be disabled by the artist/admin via `disableSignedMinting`
     */
    mapping(bytes32 => bool) private _disableSignedMinting;

    mapping(bytes32 => bool) private _signedMints;

    /**
     * @dev Permissions set at the project level.
     */
    mapping(bytes32 => bool) private _mintingPermissionsProjectLevel;

    /**
     * @dev Permissions set at the contract level.
     */
    mapping(bytes32 => bool) private _mintingPermissionsContractLevel;

    event PermissionGrantedContract(
        address indexed core,
        address indexed to,
        address by
    );

    event PermissionRevokedContract(
        address indexed core,
        address indexed to,
        address by
    );

    event PermissionGrantedProject(
        address indexed core,
        uint256 indexed projectId,
        address indexed to,
        address by
    );
    event PermissionRevokedProject(
        address indexed core,
        uint256 indexed projectId,
        address indexed to,
        address by
    );

    function mintSigned(
        address to,
        uint256 projectId,
        address core,
        bytes32 tokenNonce,
        bytes calldata signature
    ) external onlyProjectCorrectlyConfigured(core, projectId) {
        bytes memory args = abi.encode(
            _MINT_SIGNED_TYPEHASH,
            msg.sender,
            to,
            projectId,
            core,
            tokenNonce
        );
        address recoveredAddress = _checkSigned(
            args,
            tokenNonce,
            signature,
            core,
            projectId
        );
        _checkAddressCanMint(core, projectId, recoveredAddress);
        _mintFromNoPermission(core, projectId, to, msg.sender);
    }

    function mint(
        address core,
        uint256 projectId,
        address to
    ) public onlyProjectCorrectlyConfigured(core, projectId) {
        _checkAddressCanMint(core, projectId, msg.sender);
        _mintFromNoPermission(core, projectId, to, msg.sender);
    }

    function _mintFromNoPermission(
        address core,
        uint256 projectId,
        address to,
        address from
    ) private {
        IArtblocksCore artblocksCore = IArtblocksCore(core);
        artblocksCore.mint_Ecf(to, projectId, from);
    }

    function hasMintingPermission(
        address core,
        uint256 projectId,
        address sender
    ) public view returns (bool) {
        IArtblocksCore artblocksCore = IArtblocksCore(core);

        if (
            _mintingPermissionsContractLevel[
                keccak256(abi.encodePacked(core, sender))
            ]
        ) {
            return true;
        }
        if (
            _mintingPermissionsProjectLevel[
                keccak256(abi.encodePacked(core, projectId, sender))
            ]
        ) {
            return true;
        }
        return artblocksCore.projectIdToArtistAddress(projectId) == sender;
    }

    function grantContractPermission(
        address core,
        address to
    ) public onlyAdmin(core, this.grantContractPermission.selector) {
        bytes32 permissionHash = keccak256(abi.encodePacked(core, to));
        _mintingPermissionsContractLevel[permissionHash] = true;
        emit PermissionGrantedContract(core, to, msg.sender);
    }

    function revokeContractPermission(
        address core,
        address to
    ) public onlyAdmin(core, this.revokeContractPermission.selector) {
        bytes32 permissionHash = keccak256(abi.encodePacked(core, to));
        delete _mintingPermissionsContractLevel[permissionHash];
        emit PermissionRevokedContract(core, to, msg.sender);
    }

    function grantProjectPermission(
        address core,
        uint256 projectId,
        address to
    )
        public
        onlyAdminOrArtist(core, projectId, this.grantProjectPermission.selector)
        onlyProjectCorrectlyConfigured(core, projectId)
    {
        bytes32 permissionHash = keccak256(
            abi.encodePacked(core, projectId, to)
        );
        _mintingPermissionsProjectLevel[permissionHash] = true;
        emit PermissionGrantedProject(core, projectId, to, msg.sender);
    }

    function revokeProjectPermission(
        address core,
        uint256 projectId,
        address to
    )
        public
        onlyAdminOrArtist(
            core,
            projectId,
            this.revokeProjectPermission.selector
        )
        onlyProjectCorrectlyConfigured(core, projectId)
    {
        bytes32 permissionHash = keccak256(
            abi.encodePacked(core, projectId, to)
        );
        delete _mintingPermissionsProjectLevel[permissionHash];
        emit PermissionRevokedProject(core, projectId, to, msg.sender);
    }

    modifier onlyAdmin(address core, bytes4 _selector) {
        IArtblocksCore artblocksCore = IArtblocksCore(core);
        require(
            artblocksCore.adminACLAllowed(msg.sender, address(this), _selector),
            "Only admin"
        );
        _;
    }

    modifier onlyAdminOrArtist(
        address core,
        uint256 projectId,
        bytes4 _selector
    ) {
        IArtblocksCore artblocksCore = IArtblocksCore(core);
        require(
            artblocksCore.projectIdToArtistAddress(projectId) == msg.sender ||
                artblocksCore.adminACLAllowed(
                    msg.sender,
                    address(this),
                    _selector
                ),
            "Only artist or admin"
        );
        _;
    }

    /**
     * Checks if the project is correctly configured - a sanity check.
     * 1. The project must have an artist address set - This confirms the project exists
     * 2. The project must have this contract set as the minter - Otherwise we can't mint
     */
    function projectCorrectlyConfigured(
        address _core,
        uint256 _projectId
    ) public view returns (bool) {
        IArtblocksCore artblocksCore = IArtblocksCore(_core);
        if (artblocksCore.projectIdToArtistAddress(_projectId) == address(0))
            return false;
        return artblocksCore.minterContract() == address(this);
    }

    modifier onlyProjectCorrectlyConfigured(address _core, uint256 _projectId) {
        require(
            projectCorrectlyConfigured(_core, _projectId),
            "Project not correctly configured"
        );
        _;
    }

    function allowSignedMinting(
        address core,
        uint256 projectId
    )
        public
        view
        onlyProjectCorrectlyConfigured(core, projectId)
        returns (bool)
    {
        return
            !_disableSignedMinting[
                keccak256(abi.encodePacked(core, projectId))
            ];
    }

    function enableSignedMinting(
        address core,
        uint256 projectId
    )
        external
        onlyAdminOrArtist(core, projectId, this.enableSignedMinting.selector)
        onlyProjectCorrectlyConfigured(core, projectId)
    {
        _disableSignedMinting[
            keccak256(abi.encodePacked(core, projectId))
        ] = false;
    }

    function disableSignedMinting(
        address core,
        uint256 projectId
    )
        external
        onlyAdminOrArtist(core, projectId, this.disableSignedMinting.selector)
        onlyProjectCorrectlyConfigured(core, projectId)
    {
        _disableSignedMinting[
            keccak256(abi.encodePacked(core, projectId))
        ] = true;
    }

    function _checkAddressCanMint(
        address core,
        uint256 projectId,
        address sender
    ) private view {
        require(
            hasMintingPermission(core, projectId, sender),
            "Not authorized to mint"
        );
    }

    function minterType() external pure returns (string memory) {
        return "VerisartArtblocksIntegrationMinter";
    }

    function _checkSigned(
        bytes memory args,
        bytes32 tokenNonce,
        bytes memory signature,
        address core,
        uint256 projectId
    ) private returns (address) {
        require(
            allowSignedMinting(core, projectId),
            "Signed minting not allowed"
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _eip712DomainSeparator,
                keccak256(args)
            )
        );
        require(
            _signedMints[tokenNonce] == false,
            "Signed mint already redeemed"
        );
        _signedMints[tokenNonce] = true;
        return ECDSA.recover(digest, signature);
    }
}
