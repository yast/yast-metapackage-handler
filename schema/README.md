## One Click Install Specification

Get an overview [here](https://en.opensuse.org/openSUSE:One_Click_Install_Developer).
XML schema definition is documented [here](https://en.opensuse.org/openSUSE:One_Click_Install_specification).

The YMP files look a bit different depending on whether they were created for a package or a pattern. Here are two examples:

- [sample_from_package.ymp](sample_from_package.ymp)
- [sample_from_pattern.ymp](sample_from_pattern.ymp)

### Schema Conversion

```sh
trang oneclick.rnc oneclick.rng
trang oneclick.rnc oneclick.xsd
```

### XML Validation

Use one of these commands:

```sh
xmllint --noout --relaxng oneclick.rng foo.xml
jing -c oneclick.rnc foo.xml
```
