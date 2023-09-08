package calvin.example;

import lombok.Value;
import lombok.extern.slf4j.Slf4j;
import org.checkerframework.checker.nullness.qual.NonNull;
import org.checkerframework.checker.nullness.qual.Nullable;

@Slf4j
public class Basics {

  @Value
  static class NullableStringWrapper {
    @Nullable String val;
  }

  public void test1(NullableStringWrapper t) {
    log.info("equal? {}", t.getVal().equals(""));
  }

  @Value
  static class StringWrapper {
    @NonNull String val;
  }

  public void test2(StringWrapper t) {
    log.info("equal? {}", t.getVal().equals(""));
  }

}
