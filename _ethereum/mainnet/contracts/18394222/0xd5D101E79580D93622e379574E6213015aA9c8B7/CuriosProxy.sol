// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./ICuriosForProxy.sol";
import "./Ownable.sol";

contract CuriosProxy is Ownable {
    ICuriosForProxy public CURIOS;
    IPoppetsForProxy public POPPETS;
    mapping(address => bool) public isApproved;
    uint256[][] private _amounts;

    // this should be amounts: [[0], [1], [1,1], [1,1,1], [1,1,1,1], [1,1,1,1,1], [1,1,1,1,1,1], [1,1,1,1,1,1,1]]
    constructor(address _curios, address _poppets, uint256[][] memory amounts) {
        CURIOS = ICuriosForProxy(_curios);
        POPPETS = IPoppetsForProxy(_poppets);

        // _amounts.push([0]);
        // _amounts.push([1]);
        // _amounts.push([1, 1]);
        // _amounts.push([1, 1, 1]);
        // _amounts.push([1, 1, 1, 1]);
        // _amounts.push([1, 1, 1, 1, 1]);
        // _amounts.push([1, 1, 1, 1, 1, 1]);

        _amounts = amounts;

        isApproved[_poppets] = true;
    }

    modifier onlyApproved() {
        if (!isApproved[msg.sender]) {
            revert(
                "CurioProxy: Only approved addresses can call this function"
            );
        }
        _;
    }

    function approve(address _address) external onlyOwner {
        isApproved[_address] = true;
    }

    function revoke(address _address) external onlyOwner {
        isApproved[_address] = false;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 /* amount */,
        bytes calldata data
    ) external onlyApproved {
        CURIOS.safeTransferFrom(from, to, id, 1, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata /* amounts */,
        bytes calldata data
    ) external onlyApproved {
        CURIOS.safeBatchTransferFrom(from, to, ids, _amounts[ids.length], data);
    }

    function mintFromPoppets(uint[] calldata ids) external onlyApproved {
        CURIOS.mintFromPoppets(ids);
    }

    function mintFromPack(
        address to_,
        uint[] calldata ids
    ) external onlyApproved {
        CURIOS.mintFromPack(to_, ids);
    }

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256) {
        return CURIOS.balanceOf(account, id);
    }

    function allOwnedBy(
        address account,
        uint256 end_common
    ) external view returns (uint256[] memory, uint256[] memory) {
        uint256 count = 0;
        uint256 balance = 0;
        uint256 end_special = CURIOS.nextToken();

        end_common += 1;

        for (uint256 i = 0; i < end_special; i++) {
            balance = CURIOS.balanceOf(account, i);
            if (balance > 0) {
                count++;
            }
        }

        for (uint256 i = 100_000; i < end_common; i++) {
            balance = CURIOS.balanceOf(account, i);
            if (balance > 0) {
                count++;
            }
        }

        uint256[] memory ownedTokens = new uint256[](count);
        uint256[] memory balances = new uint256[](count);

        count = 0;

        for (uint256 i = 0; i < end_special; ++i) {
            balance = CURIOS.balanceOf(account, i);

            if (balance > 0) {
                ownedTokens[count] = i;
                balances[count] = balance;
                count++;
            }
        }

        for (uint256 i = 100_000; i < end_common; ++i) {
            balance = CURIOS.balanceOf(account, i);
            if (balance > 0) {
                ownedTokens[count] = i;
                balances[count] = balance;
                count++;
            }
        }

        return (ownedTokens, balances);
    }

    function withdraw() public payable {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function poppetsOwnedBy(
        address owner
    ) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = POPPETS.balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);

            for (uint256 i = 1; tokenIdsIdx != tokenIdsLength; ++i) {
                currOwnershipAddr = POPPETS.ownerOf(i);

                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}
