// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

import "./IBucketStorage.sol";

/**
 * @notice Stores a list of compressed buckets in contract code.
 */
contract ExtraBackgrounds003BucketStorage0 is IBucketStorage {
    /**
     * @notice Returns number of buckets stored in this contract.
     */
    function numBuckets() external pure returns (uint256) {
        return 1;
    }

    /**
     * @notice Returns the number of fields stored in this contract.
     */
    function numFields() external pure returns (uint256) {
        return 1;
    }

    /**
     * @notice Returns number of fields in each bucket in this storge.
     */
    function numFieldsPerBucket() external pure returns (uint256[] memory) {
        bytes memory num_ = hex"01";

        uint256[] memory num = new uint[](1);
        for (uint256 i; i < 1;) {
            num[i] = uint8(num_[i]);
            unchecked {
                ++i;
            }
        }
        return num;
    }

    /**
     * @notice Returns the bucket with a given index.
     * @dev Reverts if the index is out-of-bounds.
     */
    function getBucket(uint256 idx) external pure returns (Compressed memory) {
        if (idx == 0) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"ecd3f953d377e2c771bfdfe94c67b7d3dda96edddd11681010854288dc0875b505244481c8150847081808f7d18255298816817ad4ea50bb6da98280a848c15b210282b10ae1cc4112727c727e92cf2709c11c5cef1d017fda1ff8697fcb5ff09ae7bce6b1e9ff376ddae4e6b6ab5d14f8481bf4584e9181b05171a6d1948008d316b9718627b1700bddf84b05527f4e71fc16f2f503a860804f85d425a2c9143923caca8803bf47b30afe0e9a93211a4e14b37b9e78d0121c67f6a4ccbb14ea5caa50b74bd3db7e10b8f4cced1730ed9ef1439483de8abbbeda165fdd77eef233bbe16a9c0ad3c4f6bbaffeac4f9d8b82682e9c6d5e20aab87186d108f99d03b33fa62abfcf977e53c32fbe2a2dbcc5a53e1c270d306324d3694d47ff04c6693d19ff2738e63c53b0639ae4c4c5bbeb0e1e7813483479a4bfd95164dc75ca88bdc277bc027dfad87240fa1af35cb857dd8f9375e154bf62d5a79d67d7d6715d4a9fbbcac047b224e1cabf9833a9889e3c27a50328d9dc9f88b617599b2b90fa0baaca1b70f97d693e839b2e834bf92c927af0b0b9f730e84b19cddf0aaea740349c2231d0184358de9764f5a2ea3074edf6136a97f3235b1a38984e85dfd88b6d8c697f09032b7d126cbce68d5cc469ce071aea02f5ee1d12ef1e453c1ba44380a25ecc362f840b4792cd53a1929b11a22b89928612e5a913d3b9edeaaf6e71a94fa753069831721ef5eab10f960612074b3ee25538b2e9db8514f7a9305794108ee0f0562fea9b1d458853e54a500bef9346d47f48b79727f09ae2ed91f77a88fbf69a2e3a091bdc64351ef2e39f42aead42ec1de9cef6c92c15f0793a4ad6a0b465e40810a52f0d27206de5a0a3487ef292f6e4afa2bc1e11fd3e2b41ac281c1d206887e3970749a097fc47ce667083c24e7286c92148641838403179a46bed69733b6ba40e67581f9f1dfb679b2a60a2f7a37b6bedddde705bc0dc390fe5597f5dad3fea774f1bf050439180588e250b01d9e6857d9c17e94bbccf45372225ff8e9b3d73146d38319ddb6dacea12d086668f0cbe246ac5f49fcade9b7f1ccd28f8905b8e19cfb28768b8c9d01dc61882da236c717796c9b558e5701484b4b1ed2e198298480807f2e7cf042b1858e970f8ca4527e1f75ef0b75eaa6fb00ae7e619cf4e89730b2b470bbc9f8c903568f60a4a0582f4a5e1786d6b05b85900555d466a7e16d27b44f47ba3f15255f1487f24ca4c04c364d097f28abe05dcca5c6bd7447c01f0549347bac6eec8bcdb69897dedd8d673ac7fb4c241534ffedab3d6de8553b5071abf73979ff5d77deb877877abfd1fc0a9b3802458a66a966926eb7e2e33c5cafe5c74032ffe295e5457aeadab64e775192abb04b4e7c2aca157b11a51ce2fe5ef9b7b0f3f2bfc0bafc2712a1bb3d66e88c2c39ee10bb84c936b318c3906825b39f6970d414cf433aec497c70f5132b0d2e7a14b3f38cf5ec0aad7dab19d72ef1e05f6ce4caa04f833c6936124c3a2ca0692d485e70948db972bed5fc2b597919a5665d94359611f270d52974c3189aa01a2a52f163c26bdfdbd2d4d4871572707eb0f4580b0340b360371c8d6b954c930f5235b1a26ed3a94fee3035b1fb303a4fd38d9c3407d5bc0dc459ce642d05c5da0dead5de4dd2dc78f58286a102b36649a4c04e944f29b093cd419216e242b2fe4cbaa2bf905cd8ad23bbcccde4972ff8b68f104f9b7afff0c06498c820fa7cbec39b94ed3c92e9c08372d3ed4e01f65c166189d0be65caaadbe4d7c8746d8bbdfb08fcf7167adfdfe24d8d8b853dae0263be5a938e121f3e994f9dc957b3f85889265ff3f66483a5d9a112a055086e95912da9abfd05c84d6d7c2c75b34e54fa5b9c3ec74055c2a5cf56e5df5fe3a7f2b684d1165e36489817344c2d2fe75efa8e3098dcb79d6e60dbc635b85beddb2433c10a70471da05ca823552f82acb3c7548dc7150d47818aaa7a94f9570739ae1afbab994a1a9e461668c92476d3ef6c1caaa774e85e354ee765e86fb58b82b72301cdebdeeddb0bd1204b5081d36f0ee7e8d87eb14636e4e2469c14ec6481c8ae42e6b8a813867712819b95e026e64294fd6e9aaae88f31e89b219a3713245e1d800011d8e07abde99399b41076522d9599112a22584818875ef26d71a99c399c9bf6de07d4fb77acf43982403788185a45f49b75a423943f4251e61b63d4a72255a5c5ba06f28e1e6dc9eafba2fc81a1566be784944c5f49fcbde33ad7a6797635847ec45d93856d88e392241e1b9ee5d6bffd6fbccb60dbcef6c627bdd16d9b58da6ea816bdfeb58449bb7a2cd07829cc5a1246d4b29e8a0caabeaf5d58db3f447a2ecbe915885aa98d51fa97fe7fd257d0bb89db9d60ee3bf0091ebde2dbb4e43f6b5531f6fe03de08e22e8813a5e020e899712d0a574ab258c3b4cb3b209b3ed87c43fc648cee4a175a53cfacdb9cafb82ac1101f5e5ab584494d354febe75d53ba7c2712207b3d6ae8fc62bb1ebded14fde7ae7db6de0dde7a6d4af47eedacd3b2c07ee0363b188f68845510aa434eb603272bd08b4d1b5b5f5faeaabaab23e59fe0b768a525dc26612e101e2c2aaf7b7bfb7a7f132dce5e4605d5404085ff76e74ae5260eac7376fe0ddf3bac0e7772874cc4cd200026448359b62a071ea9b8918e8f6415163a2ea7ca6a2ba5c58f09bb2b48797f17c326968d5fbb577de27cbeca7f39c26c92e9378374d64a8ee9df77997ea45df26e146defd6ecbfc7ae4b8a7509464d9e7152f41afa318256500ca343d23a3adb98bd7f275f5a735ebde999c54d5aa77cd7f799792de7a5f78e75dbfea7ddce6dde6dde6dde6dde6dde6dde6dde6dde6dde6dde6fd7fe9fd3f010000ffff"
            });
        }

        revert InvalidBucketIndex();
    }
}
