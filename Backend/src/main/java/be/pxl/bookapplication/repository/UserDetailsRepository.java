package be.pxl.bookapplication.repository;

import be.pxl.bookapplication.domain.UserDetails;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserDetailsRepository extends JpaRepository<UserDetails, Long> {
    UserDetails findByUserId(long userid);

}
