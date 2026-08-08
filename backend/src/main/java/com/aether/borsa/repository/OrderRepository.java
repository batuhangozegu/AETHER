package com.aether.borsa.repository;

import com.aether.borsa.model.entity.Order;
import com.aether.borsa.model.entity.User;
import com.aether.borsa.model.enums.OrderStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface OrderRepository extends JpaRepository<Order, UUID> {

    List<Order> findByUser(User user);
    List<Order> findByUserAndStatus(User user, OrderStatus status);
    List<Order> findByUserAndStatusAndClosedAtAfter(User user, OrderStatus status, LocalDateTime dateTime);
    List<Order> findByUserAndStatusOrderByCreatedAtDesc(User user, OrderStatus status, Pageable pageable);
    List<Order> findByUserOrderByCreatedAtDesc(User user, Pageable pageable);
}
