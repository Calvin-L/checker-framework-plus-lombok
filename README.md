# Checker Framework + Lombok, in perfect (?) harmony

Despite [claims to the contrary](https://github.com/typetools/checker-framework/issues/3387),
the Checker Framework is actually compatible with Lombok.  However, a quirk of
how Lombok works means that the order of annotation processors matters, and
_the Checker Framework processors must be listed first_.  This is confusing
because the Checker Framework processors are indended to run _last_.

This repo demonstrates a functioning project that combines the two.

Install Maven and run `mvn verify` to compile the project.  It should fail
(expected!) with

    [ERROR] /Users/cloncaric/src/checker-framework-plus-lombok/src/main/java/calvin/example/Basics.java:[15,19] error: [dereference.of.nullable] dereference of possibly-null reference t.getVal()

**This error indicates that the Checker Framework is working**.  It shows that
the Checker Framework was able to report an error about a misuse of a
Lombok-generated method.

You can also demonstrate this with `./compile-by-hand.sh`, which shows a simple
invocation of `javac` without all of Maven's machinery.

## Why the Checker Framework must be listed first

**Background: annotation processing.**
Javac runs annotation processors before typechecking.  Each processor
advertises a set of class-level annotations that it is interested in using the
`@SupportedAnnotationTypes` annotation or by overriding
`getSupportedAnnotationTypes`.  Javac will only run a processor on a class if
that class has a class-level annotation that the processor is interested in.  A
processor can advertise interest in _all_ annotations using
`@SupportedAnnotationTypes("*")`, in which case it will run on every class,
even if the class has no class-level annotations.

One strange quirk of the annotation processing machinery is that [if there are
two processors with `@SupportedAnnotationTypes("*")` and the first of them
returns `true` from its `process` method, then the second is not guaranteed to
run](https://bugs.openjdk.org/browse/JDK-8312460?focusedCommentId=14597634&page=com.atlassian.jira.plugin.system.issuetabpanels%3Acomment-tabpanel#comment-14597634).

**Background: how Lombok processes annotations**
Lombok's annotation processor [adversises interest in all annotations](https://github.com/projectlombok/lombok/blob/000ce6d19a3d4a7d8c88ffa51e47ffda2a3b2c79/src/core/lombok/core/AnnotationProcessor.java#L52).
Furthermore, [its `process` method returns true when all the annotations on the
class are Lombok annotations and there is at least one of them](https://github.com/projectlombok/lombok/blob/000ce6d19a3d4a7d8c88ffa51e47ffda2a3b2c79/src/core/lombok/core/AnnotationProcessor.java#L257C32-L257C32).

**Background: how the Checker Framework processes annotations**
The Checker Framework annotation processors [advertise interest in all
annotations](https://github.com/typetools/checker-framework/blob/f2a190b914ab369037a156b630c55d4bed26a64f/framework/src/main/java/org/checkerframework/framework/source/SourceChecker.java#L1938).
Their [`process` methods always return false](https://github.com/typetools/checker-framework/blob/f2a190b914ab369037a156b630c55d4bed26a64f/javacutil/src/main/java/org/checkerframework/javacutil/AbstractTypeProcessor.java#L114).
However, because javac runs annotation processors before typechecking, their
process methods do not actually run the respective checker.  Instead, they
[register a callback to be invoked later, after typechecking has completed](https://github.com/typetools/checker-framework/blob/f2a190b914ab369037a156b630c55d4bed26a64f/javacutil/src/main/java/org/checkerframework/javacutil/AbstractTypeProcessor.java#L96).

**Summing up**
The unfortunate combination of background facts leads to incorrect behavior for
classes that have class-level Lombok annotations and no other annotations, e.g.
```
@lombok.Slf4j
public class Basics {
    ...
}
```
For such classes, Lombok returns true from its `process` method, preventing the
Checker Framework from running at all.  By running the Checker Framework first,
it has a chance to register its callback before Lombok ends javac's annotation
processing.  The callback will then run after typechecking, once Lombok has
finished its rewriting work.
