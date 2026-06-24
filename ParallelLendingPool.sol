// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ParallelLendingPool
 * @dev Lending vault structure tracking isolated account positions to allow conflict-free parallel liquidations.
 */
contract ParallelLendingPool {
    
    struct UserPosition {
        uint256 collateralAmount;
        uint256 borrowedAmount;
        bool isLiquidatable;
    }

    // Maps accounts directly to isolated storage footprints, maximizing OCC concurrency limits
    mapping(address => UserPosition) public positions;

    event Liquidated(address indexed user, address indexed liquidator, uint256 debtRepaid, uint256 collateralSeized);

    /**
     * @notice Liquidates an isolated distressed account.
     * @dev Designed with independent account state targets to ensure concurrent calls do not conflict.
     */
    function liquidatePosition(address borrower) external {
        UserPosition storage pos = positions[borrower];
        require(pos.isLiquidatable, "LendingError: Target position remains healthy");
        
        uint256 debtToRepay = pos.borrowedAmount;
        uint256 collateralToSeize = pos.collateralAmount;

        pos.borrowedAmount = 0;
        pos.collateralAmount = 0;
        pos.isLiquidatable = false;

        emit Liquidated(borrower, msg.sender, debtToRepay, collateralToSeize);
    }
}
